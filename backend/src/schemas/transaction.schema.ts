import Joi from 'joi';

export const transactionSchema = {
  create: Joi.object({
    amount: Joi.number().required().greater(0),
    type: Joi.string().valid('INCOME', 'EXPENSE').required(),
    category: Joi.string().required(),
    description: Joi.string(),
    date: Joi.date().iso().required(),
    contactId: Joi.string().uuid(),
    budgetId: Joi.string().uuid(),
    paymentMethod: Joi.string().valid('UPI', 'CASH', 'BANK_TRANSFER', 'CARD', 'OTHER').required(),
    status: Joi.string().valid('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED').default('COMPLETED'),
    attachments: Joi.array().items(
      Joi.object({
        url: Joi.string().uri().required(),
        type: Joi.string().valid('IMAGE', 'PDF', 'OTHER').required(),
        name: Joi.string().required(),
      })
    ),
    location: Joi.object({
      latitude: Joi.number().min(-90).max(90),
      longitude: Joi.number().min(-180).max(180),
      address: Joi.string(),
    }),
    tags: Joi.array().items(Joi.string()),
  }),

  update: Joi.object({
    amount: Joi.number().greater(0),
    type: Joi.string().valid('INCOME', 'EXPENSE'),
    category: Joi.string(),
    description: Joi.string(),
    date: Joi.date().iso(),
    contactId: Joi.string().uuid(),
    budgetId: Joi.string().uuid(),
    paymentMethod: Joi.string().valid('UPI', 'CASH', 'BANK_TRANSFER', 'CARD', 'OTHER'),
    status: Joi.string().valid('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED'),
    attachments: Joi.array().items(
      Joi.object({
        url: Joi.string().uri().required(),
        type: Joi.string().valid('IMAGE', 'PDF', 'OTHER').required(),
        name: Joi.string().required(),
      })
    ),
    location: Joi.object({
      latitude: Joi.number().min(-90).max(90),
      longitude: Joi.number().min(-180).max(180),
      address: Joi.string(),
    }),
    tags: Joi.array().items(Joi.string()),
  }),

  filter: Joi.object({
    startDate: Joi.date().iso(),
    endDate: Joi.date().iso().min(Joi.ref('startDate')),
    type: Joi.string().valid('INCOME', 'EXPENSE'),
    category: Joi.string(),
    minAmount: Joi.number().min(0),
    maxAmount: Joi.number().min(Joi.ref('minAmount')),
    contactId: Joi.string().uuid(),
    budgetId: Joi.string().uuid(),
    paymentMethod: Joi.string().valid('UPI', 'CASH', 'BANK_TRANSFER', 'CARD', 'OTHER'),
    status: Joi.string().valid('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED'),
    tags: Joi.array().items(Joi.string()),
    sortBy: Joi.string().valid('date', 'amount', 'category'),
    sortOrder: Joi.string().valid('asc', 'desc').default('desc'),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
  }),

  addAttachment: Joi.object({
    url: Joi.string().uri().required(),
    type: Joi.string().valid('IMAGE', 'PDF', 'OTHER').required(),
    name: Joi.string().required(),
  }),

  removeAttachment: Joi.object({
    attachmentId: Joi.string().required(),
  }),

  updateTags: Joi.object({
    tags: Joi.array().items(Joi.string()).required(),
  }),
}; 