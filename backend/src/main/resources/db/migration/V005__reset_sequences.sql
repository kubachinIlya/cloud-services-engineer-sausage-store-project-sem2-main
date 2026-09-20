--  что sequence существуют
CREATE SEQUENCE IF NOT EXISTS orders_id_seq;
CREATE SEQUENCE IF NOT EXISTS product_id_seq;

-- Привязываем sequence к колонкам как DEFAULT
ALTER TABLE orders ALTER COLUMN id SET DEFAULT nextval('orders_id_seq');
ALTER TABLE product ALTER COLUMN id SET DEFAULT nextval('product_id_seq');

-- Синхронизируем sequence со значениями MAX(id)
-- setval устанавливает следующее значение = MAX(id) + 1
SELECT setval('orders_id_seq', (SELECT MAX(id) FROM orders));
SELECT setval('product_id_seq', (SELECT MAX(id) FROM product));