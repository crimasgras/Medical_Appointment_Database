
CREATE OR REPLACE FUNCTION log_appointment_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO appointment_audit(appointment_id, action)
    VALUES (NEW.appointment_id, 'INSERT');
    RETURN NEW;
END;
$$;


CREATE OR REPLACE FUNCTION log_appointment_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO appointment_audit(appointment_id, action)
    VALUES (NEW.appointment_id, 'UPDATE');
    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_log_appointment_insert
AFTER INSERT ON appointments
FOR EACH ROW
EXECUTE FUNCTION log_appointment_insert();


CREATE TRIGGER trg_log_appointment_update
AFTER UPDATE ON appointments
FOR EACH ROW
EXECUTE FUNCTION log_appointment_update();
