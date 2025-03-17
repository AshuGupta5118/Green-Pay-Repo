import Joi from 'joi';

export const contactSchema = {
  create: Joi.object({
    name: Joi.string().required(),
    phoneNumber: Joi.string().pattern(/^\+?[0-9]{10,}$/),
    email: Joi.string().email(),
    upiId: Joi.string().pattern(/^[a-zA-Z0-9.\-_]{2,49}@[a-zA-Z]{2,}$/),
    notes: Joi.string(),
  }).or('phoneNumber', 'email', 'upiId'),

  update: Joi.object({
    name: Joi.string(),
    phoneNumber: Joi.string().pattern(/^\+?[0-9]{10,}$/),
    email: Joi.string().email(),
    upiId: Joi.string().pattern(/^[a-zA-Z0-9.\-_]{2,49}@[a-zA-Z]{2,}$/),
    notes: Joi.string(),
  }),

  sync: Joi.object({
    contacts: Joi.array().items(
      Joi.object({
        name: Joi.string().required(),
        phoneNumber: Joi.string().pattern(/^\+?[0-9]{10,}$/),
        email: Joi.string().email(),
      }).or('phoneNumber', 'email'),
    ),
  }),
}; 