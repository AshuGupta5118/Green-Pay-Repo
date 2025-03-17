import { Router } from 'express';
import { BudgetController } from '../controllers/budget.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { budgetSchema } from '../schemas/budget.schema';

const router = Router();

router.use(authenticate);

router.get('/', BudgetController.getBudgets);

router.post(
  '/',
  validate(budgetSchema.create),
  BudgetController.createBudget,
);

router.put(
  '/:id',
  validate(budgetSchema.update),
  BudgetController.updateBudget,
);

router.delete('/:id', BudgetController.deleteBudget);

router.get('/analytics', BudgetController.getSpendingAnalytics);

router.post(
  '/:id/transactions',
  validate(budgetSchema.addTransaction),
  BudgetController.updateBudgetSpending,
);

router.get('/:id/summary', BudgetController.getBudgetSummary);

export default router; 