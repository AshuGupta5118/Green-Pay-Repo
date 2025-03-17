import Joi from 'joi';

export const budgetSchema = {
  create: Joi.object({
    category: Joi.string().required(),
    limit: Joi.number().positive().required(),
    startDate: Joi.date().iso().required(),
    endDate: Joi.date().iso().min(Joi.ref('startDate')).required(),
    color: Joi.string().regex(/^#[0-9A-Fa-f]{6}$/).required(),
  }),

  update: Joi.object({
    limit: Joi.number().positive(),
    startDate: Joi.date().iso(),
    endDate: Joi.date().iso().min(Joi.ref('startDate')),
    color: Joi.string().regex(/^#[0-9A-Fa-f]{6}$/),
  }),

  addTransaction: Joi.object({
    transactionId: Joi.string().required(),
  }),
}; 