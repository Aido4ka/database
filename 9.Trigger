
-- Table: public.CAuditPrices

-- DROP TABLE public."CAuditPrices";
-- Триггеры например создается для аудита, что делали с записями таблицы например
-- Таблица цен на услуги в клинике

drop table if exists public."CAuditPrices";
CREATE TABLE public."CAuditPrices"
(
    "Price_Id"   bigint,
    "Service_Id" bigint,
    "Pdate"      date,
    "Price_Val"  numeric(18, 2),
    "DateUpdate" date
)
    WITH (
        OIDS = FALSE
    )
    TABLESPACE pg_default;

ALTER TABLE public."CAuditPrices"
    OWNER to postgres;

COMMENT ON TABLE public."CAuditPrices"
    IS 'Аудит по таблице цены на услуги';


-- FUNCTION: public.audit_dml_proc_prices()

-- DROP FUNCTION public.audit_dml_proc_prices();


CREATE FUNCTION public.audit_dml_proc_prices()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS
$BODY$
begin

    if (TG_OP = 'DELETE') then
        Insert Into public."CAuditPrices" Select OLD.*, now();
    elsif (TG_OP = 'INSERT') then
        Insert Into public."CAuditPrices" Select NEW.*, now();
    elsif (TG_OP = 'UPDATE') then
        Insert Into public."CAuditPrices" Select NEW.*, now();
    end if;
    return null;
end;
$BODY$;

ALTER FUNCTION public.audit_dml_proc_prices()
    OWNER TO postgres;
-- Trigger: CPriceTrg

-- DROP TRIGGER "CPriceTrg" ON public."Cprice";

CREATE TRIGGER "CPriceTrg"
    BEFORE INSERT OR DELETE OR UPDATE
    ON public."Cprice"
    FOR EACH ROW
EXECUTE PROCEDURE public.audit_dml_proc_prices();

--Триггеры например создается
-- Подсчитывания дохода за каждый день и записи его в таблицу public."CDayDohodValue
-- при изменении таблицы public."CatCare"


drop table if exists public."CDayDohodValue";
CREATE TABLE public."CDayDohodValue"
(
    "DateCare" date,
    "AllSumValue" numeric(18,2)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public."CDayDohodValue"
    OWNER to postgres;

COMMENT ON TABLE public."CDayDohodValue"
    IS 'Например доход на каждый день пересчитываем';


CREATE OR REPLACE FUNCTION public.total_dohod_in_day()
    RETURNS trigger AS $total_dohod_in_day$
   	  declare
	  vdate  date;
	  id     BIGINT;
	  daySumma NUMERIC(18,2);
	  daySumma1 NUMERIC(18,2);

begin

  if (TG_OP = 'DELETE') then
    id = old."reception_id";
    daySumma1 = old."calc_amt";
  elsif (TG_OP = 'INSERT') then
    id = new."reception_id";
    daySumma1 = new."calc_amt";
  elsif (TG_OP = 'UPDATE') then
    id = new."reception_id";
    daySumma1 = new."calc_amt";
  end if;

  Select a."reception_dt"
    Into strict vdate
    From public."Catreception" a
   where a."reception_id"  = id;

  Select SUM(a."calc_amt")
    Into strict daySumma
    From public."CatCare" a,
	     public."Catreception" b
   where a."reception_id"  = b."reception_id" and
         b."reception_dt" = vdate and
		 b."reception_id"<>id;
  insert into public."CDayDohodValue" values(vdate, daySumma + daySumma1);

  return null;

end;
$total_dohod_in_day$ LANGUAGE plpgsql;

ALTER FUNCTION public.total_dohod_in_day()
    OWNER TO postgres;
-- Trigger: CPriceTrg

-- DROP TRIGGER "CPriceTrg" ON public."Cprice";

CREATE TRIGGER "CCatCareTrg"
    BEFORE INSERT OR DELETE OR UPDATE
    ON public."CatCare"
    FOR EACH ROW
    EXECUTE PROCEDURE public.total_dohod_in_day();

