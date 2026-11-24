-- 1. СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ
-- Удаляем старые представления, если они существуют
DROP VIEW IF EXISTS "v5_SotrudnikiProverka";
DROP VIEW IF EXISTS "v5_SotrudnikiBezProverki";
DROP VIEW IF EXISTS "v5_ProstoePredstavlenie";
DROP VIEW IF EXISTS "v5_Sotrudniki";
DROP MATERIALIZED VIEW IF EXISTS "v5_MaterializovannoeNachislenie";


-- 1.1. ПРОСТОЕ НЕМАТЕРИАЛИЗОВАННОЕ ПРЕДСТАВЛЕНИЕ
-- Вывод информации обо всех сотрудниках
CREATE VIEW "v5_ProstoePredstavlenie" AS
SELECT
    "id_сотрудника",
    "ФИО",
    "id_должности",
    "Адрес_проживания",
    "Телефон",
    "Дата_устройства"
FROM "Sotrudnik";


-- Проверка представления
SELECT *
FROM "v5_ProstoePredstavlenie";


-- 1.2. МАТЕРИАЛИЗОВАННОЕ НЕИЗМЕНЯЕМОЕ ПРЕДСТАВЛЕНИЕ
-- Информация о начислениях сотрудников
CREATE MATERIALIZED VIEW "v5_MaterializovannoeNachislenie" AS
SELECT
    n."id_начисления",
    s."ФИО",
    w."Описание" AS "Вид_работы",
    n."Дата_начисления",
    n."Количество_часов",
    n."Налог"
FROM "Nachislenie" n
JOIN "Sotrudnik" s
    ON n."id_сотрудника" = s."id_сотрудника"
JOIN "WorkType" w
    ON n."id_вид_работы" = w."id_вид_работы";


-- Проверка материализованного представления
SELECT *
FROM "v5_MaterializovannoeNachislenie";


-- 1.3. ПРОСТОЕ ИЗМЕНЯЕМОЕ ПРЕДСТАВЛЕНИЕ
-- Нельзя изменить строку так, чтобы она перестала
-- соответствовать условию представления
CREATE VIEW "v5_SotrudnikiProverka" AS
SELECT
    "id_сотрудника",
    "ФИО",
    "id_должности",
    "id_тип_освобождения",
    "Адрес_проживания",
    "Телефон",
    "Дата_рождения",
    "Дата_устройства"
FROM "Sotrudnik"
WHERE "id_должности" IN (1, 2, 3)
WITH CHECK OPTION;


-- Проверка представления
SELECT *
FROM "v5_SotrudnikiProverka";


-- 1.4. ПРОСТОЕ ИЗМЕНЯЕМОЕ ПРЕДСТАВЛЕНИЕ
-- Можно изменить строку так, чтобы она перестала
-- отображаться в представлении
CREATE VIEW "v5_SotrudnikiBezProverki" AS
SELECT
    "id_сотрудника",
    "ФИО",
    "id_должности",
    "id_тип_освобождения",
    "Адрес_проживания",
    "Телефон",
    "Дата_рождения",
    "Дата_устройства"
FROM "Sotrudnik"
WHERE "id_должности" IN (1, 2, 3);


-- Проверка представления
SELECT *
FROM "v5_SotrudnikiBezProverki";




-- 2. ИЗМЕНЕНИЕ ДАННЫХ ЧЕРЕЗ ПРЕДСТАВЛЕНИЯ
-- 2.1. INSERT
-- Добавление нового сотрудника через представление
INSERT INTO "v5_SotrudnikiProverka"
(
    "id_сотрудника",
    "ФИО",
    "id_должности",
    "id_тип_освобождения",
    "Адрес_проживания",
    "Телефон",
    "Дата_рождения",
    "Дата_устройства"
)
VALUES
(
    9001,
    'Тестовый Сотрудник',
    1,
    1,
    'г. Москва, ул. Тестовая, 1',
    '+79990009001',
    '2000-01-01',
    '2025-01-01'
);


-- Проверка добавления
SELECT *
FROM "v5_SotrudnikiProverka"
WHERE "id_сотрудника" = 9001;


-- 2.2. UPDATE
-- Изменение должности сотрудника через представление
-- Должность 1 меняется на должность 2
UPDATE "v5_SotrudnikiProverka"
SET "id_должности" = 2
WHERE "id_сотрудника" = 9001;


-- Проверка изменения
SELECT *
FROM "v5_SotrudnikiProverka"
WHERE "id_сотрудника" = 9001;


-- Проверка WITH CHECK OPTION
-- Попытка изменить должность на 7.
-- Изменение запрещено, так как должность 7
-- не соответствует условию представления.
DO $$
BEGIN
    UPDATE "v5_SotrudnikiProverka"
    SET "id_должности" = 7
    WHERE "id_сотрудника" = 9001;

    RAISE NOTICE 'Изменение выполнено';

EXCEPTION
    WHEN SQLSTATE '44000' THEN
        RAISE NOTICE 'Изменение запрещено: WITH CHECK OPTION';
END $$;


-- 2.3. DELETE
-- Удаление тестового сотрудника через представление
DELETE FROM "v5_SotrudnikiProverka"
WHERE "id_сотрудника" = 9001;


-- Проверка удаления
SELECT *
FROM "Sotrudnik"
WHERE "id_сотрудника" = 9001;


-- 2.4. Проверка представления БЕЗ CHECK OPTION
-- Добавление второго тестового сотрудника
INSERT INTO "v5_SotrudnikiBezProverki"
(
    "id_сотрудника",
    "ФИО",
    "id_должности",
    "id_тип_освобождения",
    "Адрес_проживания",
    "Телефон",
    "Дата_рождения",
    "Дата_устройства"
)
VALUES
(
    9002,
    'Временный Сотрудник',
    1,
    1,
    'г. Москва, ул. Тестовая, 2',
    '+79990009002',
    '2001-01-01',
    '2025-02-01'
);


-- Изменение должности с 1 на 7
-- Изменение разрешено, несмотря на условие представления
UPDATE "v5_SotrudnikiBezProverki"
SET "id_должности" = 7
WHERE "id_сотрудника" = 9002;

-- Проверяем представление: сотрудник исчезнет из него
SELECT *
FROM "v5_SotrudnikiBezProverki"
WHERE "id_сотрудника" = 9002;


-- Проверяем базовую таблицу: сотрудник остался,
-- но его должность изменилась на 7
SELECT *
FROM "Sotrudnik"
WHERE "id_сотрудника" = 9002;

-- Удаляем временную запись из базовой таблицы
DELETE FROM "Sotrudnik"
WHERE "id_сотрудника" = 9002;




-- 3. ОБНОВЛЕНИЕ МАТЕРИАЛИЗОВАННОГО ПРЕДСТАВЛЕНИЯ
-- Обновление данных материализованного представления
REFRESH MATERIALIZED VIEW "v5_MaterializovannoeNachislenie";


-- Проверка обновлённых данных
SELECT *
FROM "v5_MaterializovannoeNachislenie"
ORDER BY "id_начисления";




-- 4. СОЗДАНИЕ ИНДЕКСОВ
-- 4.1. ПРОСТОЙ ИНДЕКС В ЦЕЛОЙ ТАБЛИЦЕ
-- Индекс по ФИО сотрудников
CREATE INDEX "idx_v5_sotrudnik_fio"
ON "Sotrudnik" ("ФИО");


-- Проверка индекса
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'Sotrudnik';


-- 4.2. СОСТАВНОЙ ЧАСТИЧНЫЙ ИНДЕКС
-- Индекс по дате начисления и количеству часов
-- Только для начислений, где часов не меньше 40
CREATE INDEX "idx_v5_nachislenie_data_chasy"
ON "Nachislenie"
("Дата_начисления", "Количество_часов")
WHERE "Количество_часов" >= 40;


-- Проверка индекса
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'Nachislenie';


-- 4.3. УНИКАЛЬНЫЙ ИНДЕКС
-- Уникальный индекс для материализованного представления
-- По идентификатору начисления
CREATE UNIQUE INDEX "idx_v5_materializovannoe_id"
ON "v5_MaterializovannoeNachislenie"
("id_начисления");


-- Проверка уникального индекса
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'v5_MaterializovannoeNachislenie';


-- 4.4. СОСТАВНОЙ ИНДЕКС С ЗАДАННОЙ СОРТИРОВКОЙ
-- Сортировка по дате устройства по возрастанию,
-- а по ФИО по убыванию
CREATE INDEX "idx_v5_sotrudnik_data_fio"
ON "Sotrudnik"
("Дата_устройства" ASC, "ФИО" DESC);


-- Проверка индекса
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'Sotrudnik';



-- 5. ПЕРЕИМЕНОВАНИЕ ПРЕДСТАВЛЕНИЯ
-- Переименовываем простое представление
ALTER VIEW "v5_ProstoePredstavlenie"
RENAME TO "v5_Sotrudniki";


-- Проверка переименованного представления
SELECT *
FROM "v5_Sotrudniki";




-- 6. УДАЛЕНИЕ ИНДЕКСА И ПРЕДСТАВЛЕНИЯ
-- Удаление простого индекса
DROP INDEX "idx_v5_sotrudnik_fio";


-- Удаление одного изменяемого представления
DROP VIEW "v5_SotrudnikiProverka";


-- Проверка оставшихся представлений
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name LIKE 'v5_%';


-- Проверка оставшихся индексов
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_v5_%';

