-- -----------------------------------------------------------------------------
-- Views
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.demo_view AS
SELECT t.id,
       t.val2
  FROM public.demo_table t;
