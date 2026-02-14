-- Hardens SECURITY DEFINER functions against search_path injection.
ALTER FUNCTION public.handle_new_user() SET search_path = public;
ALTER FUNCTION public.get_item_actual(UUID) SET search_path = public;
ALTER FUNCTION public.get_category_actual(UUID) SET search_path = public;
ALTER FUNCTION public.get_income_source_actual(UUID) SET search_path = public;
