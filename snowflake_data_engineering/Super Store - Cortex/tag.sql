CREATE TAG data_governance.tags.cost_center
  ALLOWED_VALUES 'finance', 'engineering';

CREATE WAREHOUSE finance_wh WITH TAG (cost_center = 'finance');