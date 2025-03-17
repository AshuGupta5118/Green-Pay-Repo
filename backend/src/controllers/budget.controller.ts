import { Request, Response } from 'express';
import { Budget } from '../models/budget.model';
import { Transaction } from '../models/transaction.model';
import { ApiError } from '../utils/api-error';

export class BudgetController {
  static async getBudgets(req: Request, res: Response) {
    const userId = req.user!.id;
    const budgets = await Budget.find({ userId });
    res.json({ data: budgets });
  }

  static async createBudget(req: Request, res: Response) {
    const userId = req.user!.id;
    const { category, limit, startDate, endDate, color } = req.body;

    const existingBudget = await Budget.findOne({ userId, category });
    if (existingBudget) {
      throw new ApiError('Budget for this category already exists', 400);
    }

    const budget = await Budget.create({
      userId,
      category,
      limit,
      startDate,
      endDate,
      color,
    });

    res.status(201).json({ data: budget });
  }

  static async updateBudget(req: Request, res: Response) {
    const userId = req.user!.id;
    const budgetId = req.params.id;
    const { limit, startDate, endDate, color } = req.body;

    const budget = await Budget.findOneAndUpdate(
      { _id: budgetId, userId },
      { limit, startDate, endDate, color },
      { new: true },
    );

    if (!budget) {
      throw new ApiError('Budget not found', 404);
    }

    res.json({ data: budget });
  }

  static async deleteBudget(req: Request, res: Response) {
    const userId = req.user!.id;
    const budgetId = req.params.id;

    const budget = await Budget.findOneAndDelete({ _id: budgetId, userId });

    if (!budget) {
      throw new ApiError('Budget not found', 404);
    }

    res.status(204).send();
  }

  static async getSpendingAnalytics(req: Request, res: Response) {
    const userId = req.user!.id;
    const { startDate, endDate } = req.query;

    const transactions = await Transaction.find({
      userId,
      type: 'expense',
      createdAt: {
        $gte: new Date(startDate as string),
        $lte: new Date(endDate as string),
      },
    });

    const totalSpent = transactions.reduce((sum, t) => sum + t.amount, 0);

    const categorySpending = await Transaction.aggregate([
      {
        $match: {
          userId,
          type: 'expense',
          createdAt: {
            $gte: new Date(startDate as string),
            $lte: new Date(endDate as string),
          },
        },
      },
      {
        $group: {
          _id: '$category',
          amount: { $sum: '$amount' },
        },
      },
      {
        $project: {
          category: '$_id',
          amount: 1,
          _id: 0,
        },
      },
    ]);

    res.json({
      data: {
        totalSpent,
        categorySpending,
      },
    });
  }

  static async updateBudgetSpending(req: Request, res: Response) {
    const userId = req.user!.id;
    const budgetId = req.params.id;
    const { transactionId } = req.body;

    const [budget, transaction] = await Promise.all([
      Budget.findOne({ _id: budgetId, userId }),
      Transaction.findOne({ _id: transactionId, userId }),
    ]);

    if (!budget) {
      throw new ApiError('Budget not found', 404);
    }

    if (!transaction) {
      throw new ApiError('Transaction not found', 404);
    }

    if (transaction.type !== 'expense') {
      throw new ApiError('Only expense transactions can be added to budgets', 400);
    }

    budget.spent += transaction.amount;
    await budget.save();

    res.json({ data: budget });
  }

  static async getBudgetSummary(req: Request, res: Response) {
    const userId = req.user!.id;
    const budgetId = req.params.id;

    const budget = await Budget.findOne({ _id: budgetId, userId });

    if (!budget) {
      throw new ApiError('Budget not found', 404);
    }

    const transactions = await Transaction.find({
      userId,
      category: budget.category,
      type: 'expense',
      createdAt: {
        $gte: budget.startDate,
        $lte: budget.endDate,
      },
    })
      .sort({ createdAt: -1 })
      .limit(10);

    res.json({
      data: {
        budget,
        recentTransactions: transactions,
      },
    });
  }
} 