import { Router } from 'express';
import { ContactController } from '../controllers/contact.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { contactSchema } from '../schemas/contact.schema';

const router = Router();

router.use(authenticate);

router.get('/', ContactController.getContacts);

router.get('/favorites', ContactController.getFavoriteContacts);

router.post(
  '/',
  validate(contactSchema.create),
  ContactController.addContact,
);

router.put(
  '/:id',
  validate(contactSchema.update),
  ContactController.updateContact,
);

router.delete('/:id', ContactController.deleteContact);

router.post('/:id/toggle-favorite', ContactController.toggleFavorite);

router.post(
  '/sync',
  validate(contactSchema.sync),
  ContactController.syncContacts,
);

router.get('/search', ContactController.searchContacts);

router.get('/:id/analytics', ContactController.getContactAnalytics);

export default router; 