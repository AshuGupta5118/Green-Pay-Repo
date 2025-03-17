import mongoose, { Schema, Document } from 'mongoose';

export interface IContact extends Document {
  userId: mongoose.Types.ObjectId;
  name: string;
  phoneNumber?: string;
  email?: string;
  upiId?: string;
  isFavorite: boolean;
  recentTransactionIds: mongoose.Types.ObjectId[];
  lastInteraction: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const contactSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    phoneNumber: {
      type: String,
      trim: true,
      sparse: true,
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      sparse: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Please enter a valid email'],
    },
    upiId: {
      type: String,
      trim: true,
      sparse: true,
      match: [/^[a-zA-Z0-9.\-_]{2,49}@[a-zA-Z]{2,}$/, 'Please enter a valid UPI ID'],
    },
    isFavorite: {
      type: Boolean,
      default: false,
    },
    recentTransactionIds: [{
      type: Schema.Types.ObjectId,
      ref: 'Transaction',
    }],
    lastInteraction: {
      type: Date,
      default: Date.now,
    },
    notes: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

contactSchema.index({ userId: 1, phoneNumber: 1 }, { unique: true, sparse: true });
contactSchema.index({ userId: 1, email: 1 }, { unique: true, sparse: true });
contactSchema.index({ userId: 1, upiId: 1 }, { unique: true, sparse: true });
contactSchema.index({ userId: 1, name: 'text' });
contactSchema.index({ userId: 1, isFavorite: 1 });

export const Contact = mongoose.model<IContact>('Contact', contactSchema); 