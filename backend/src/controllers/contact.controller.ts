import { Request, Response } from 'express';
import { Contact } from '../models/contact.model';
import { Transaction } from '../models/transaction.model';
import { ApiError } from '../utils/api-error';

export class ContactController {
  static async getContacts(req: Request, res: Response) {
    const userId = req.user!.id;
    const contacts = await Contact.find({ userId });
    res.json({ data: contacts });
  }

  static async getFavoriteContacts(req: Request, res: Response) {
    const userId = req.user!.id;
    const contacts = await Contact.find({ userId, isFavorite: true });
    res.json({ data: contacts });
  }

  static async addContact(req: Request, res: Response) {
    const userId = req.user!.id;
    const { name, phoneNumber, email, upiId, notes } = req.body;

    if (phoneNumber) {
      const existingContact = await Contact.findOne({ userId, phoneNumber });
      if (existingContact) {
        throw new ApiError('Contact with this phone number already exists', 400);
      }
    }

    if (email) {
      const existingContact = await Contact.findOne({ userId, email });
      if (existingContact) {
        throw new ApiError('Contact with this email already exists', 400);
      }
    }

    if (upiId) {
      const existingContact = await Contact.findOne({ userId, upiId });
      if (existingContact) {
        throw new ApiError('Contact with this UPI ID already exists', 400);
      }
    }

    const contact = await Contact.create({
      userId,
      name,
      phoneNumber,
      email,
      upiId,
      notes,
    });

    res.status(201).json({ data: contact });
  }

  static async updateContact(req: Request, res: Response) {
    const userId = req.user!.id;
    const contactId = req.params.id;
    const { name, phoneNumber, email, upiId, notes } = req.body;

    const contact = await Contact.findOneAndUpdate(
      { _id: contactId, userId },
      { name, phoneNumber, email, upiId, notes },
      { new: true },
    );

    if (!contact) {
      throw new ApiError('Contact not found', 404);
    }

    res.json({ data: contact });
  }

  static async deleteContact(req: Request, res: Response) {
    const userId = req.user!.id;
    const contactId = req.params.id;

    const contact = await Contact.findOneAndDelete({ _id: contactId, userId });

    if (!contact) {
      throw new ApiError('Contact not found', 404);
    }

    res.status(204).send();
  }

  static async toggleFavorite(req: Request, res: Response) {
    const userId = req.user!.id;
    const contactId = req.params.id;

    const contact = await Contact.findOne({ _id: contactId, userId });

    if (!contact) {
      throw new ApiError('Contact not found', 404);
    }

    contact.isFavorite = !contact.isFavorite;
    await contact.save();

    res.json({ data: contact });
  }

  static async syncContacts(req: Request, res: Response) {
    const userId = req.user!.id;
    const { contacts: deviceContacts } = req.body;

    const syncedContacts = [];

    for (const deviceContact of deviceContacts) {
      const { name, phoneNumber, email } = deviceContact;

      let contact = await Contact.findOne({
        userId,
        $or: [
          { phoneNumber },
          { email },
        ].filter(Boolean),
      });

      if (!contact) {
        contact = await Contact.create({
          userId,
          name,
          phoneNumber,
          email,
        });
      }

      syncedContacts.push(contact);
    }

    res.json({ data: syncedContacts });
  }

  static async searchContacts(req: Request, res: Response) {
    const userId = req.user!.id;
    const { q } = req.query;

    const contacts = await Contact.find({
      userId,
      $text: { $search: q as string },
    });

    res.json({ data: contacts });
  }

  static async getContactAnalytics(req: Request, res: Response) {
    const userId = req.user!.id;
    const contactId = req.params.id;

    const contact = await Contact.findOne({ _id: contactId, userId });

    if (!contact) {
      throw new ApiError('Contact not found', 404);
    }

    const transactions = await Transaction.find({
      userId,
      $or: [
        { fromUserId: userId, toContactId: contactId },
        { toUserId: userId, fromContactId: contactId },
      ],
    })
      .sort({ createdAt: -1 })
      .limit(10);

    const totalSent = await Transaction.aggregate([
      {
        $match: {
          userId,
          fromUserId: userId,
          toContactId: contactId,
        },
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$amount' },
        },
      },
    ]);

    const totalReceived = await Transaction.aggregate([
      {
        $match: {
          userId,
          toUserId: userId,
          fromContactId: contactId,
        },
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$amount' },
        },
      },
    ]);

    res.json({
      data: {
        contact,
        recentTransactions: transactions,
        totalSent: totalSent[0]?.total || 0,
        totalReceived: totalReceived[0]?.total || 0,
      },
    });
  }
} 