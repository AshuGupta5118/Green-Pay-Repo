const Transaction = require('../models/transaction.model');
const mongoose = require('mongoose');

// Get transaction summary
const getTransactionSummary = async (req, res) => {
  try {
    const userId = req.user._id;
    const { startDate, endDate } = req.query;

    const dateFilter = {};
    if (startDate || endDate) {
      dateFilter.createdAt = {};
      if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
      if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
    }

    const summary = await Transaction.aggregate([
      {
        $match: {
          $and: [
            { $or: [{ sender: userId }, { receiver: userId }] },
            { status: 'SUCCESS' },
            dateFilter
          ]
        }
      },
      {
        $facet: {
          totalTransactions: [
            { $count: 'count' }
          ],
          totalAmount: [
            {
              $group: {
                _id: null,
                amount: { $sum: '$amount' }
              }
            }
          ],
          byType: [
            {
              $group: {
                _id: '$type',
                count: { $sum: 1 },
                amount: { $sum: '$amount' }
              }
            }
          ],
          sent: [
            {
              $match: { sender: userId }
            },
            {
              $group: {
                _id: null,
                count: { $sum: 1 },
                amount: { $sum: '$amount' }
              }
            }
          ],
          received: [
            {
              $match: { receiver: userId }
            },
            {
              $group: {
                _id: null,
                count: { $sum: 1 },
                amount: { $sum: '$amount' }
              }
            }
          ]
        }
      }
    ]);

    const result = summary[0];
    res.json({
      status: 'success',
      data: {
        total: {
          count: result.totalTransactions[0]?.count || 0,
          amount: result.totalAmount[0]?.amount || 0
        },
        byType: result.byType.reduce((acc, curr) => {
          acc[curr._id.toLowerCase()] = {
            count: curr.count,
            amount: curr.amount
          };
          return acc;
        }, {}),
        sent: {
          count: result.sent[0]?.count || 0,
          amount: result.sent[0]?.amount || 0
        },
        received: {
          count: result.received[0]?.count || 0,
          amount: result.received[0]?.amount || 0
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Error fetching transaction summary'
    });
  }
};

// Get monthly transaction trends
const getMonthlyTrends = async (req, res) => {
  try {
    const userId = req.user._id;
    const { months = 6 } = req.query;

    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - parseInt(months));

    const trends = await Transaction.aggregate([
      {
        $match: {
          $and: [
            { $or: [{ sender: userId }, { receiver: userId }] },
            { status: 'SUCCESS' },
            { createdAt: { $gte: startDate } }
          ]
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' }
          },
          count: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
          sent: {
            $sum: {
              $cond: [{ $eq: ['$sender', userId] }, '$amount', 0]
            }
          },
          received: {
            $sum: {
              $cond: [{ $eq: ['$receiver', userId] }, '$amount', 0]
            }
          }
        }
      },
      {
        $sort: {
          '_id.year': 1,
          '_id.month': 1
        }
      }
    ]);

    res.json({
      status: 'success',
      data: {
        trends: trends.map(t => ({
          year: t._id.year,
          month: t._id.month,
          count: t.count,
          totalAmount: t.totalAmount,
          sent: t.sent,
          received: t.received
        }))
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Error fetching monthly trends'
    });
  }
};

module.exports = {
  getTransactionSummary,
  getMonthlyTrends
}; 