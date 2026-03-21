CREATE OR REPLACE PROCEDURE reschedule_appointment(
    p_appointment_id INT,
    p_new_time TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_new_time < CURRENT_TIMESTAMP THEN
        RAISE NOTICE 'New time must be in the future';
        RETURN;
    END IF;

    UPDATE appointments
    SET appointment_time = p_new_time
    WHERE appointment_id = p_appointment_id
      AND status = 'scheduled';

    IF NOT FOUND THEN
        RAISE NOTICE 'Appointment not found or not in scheduled status';
    ELSE
        RAISE NOTICE 'Appointment % rescheduled to %', p_appointment_id, p_new_time;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE cancel_all_appointments(
    p_doctor_id INT,
    p_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND DATE(appointment_time) = p_date
      AND status = 'scheduled';

    UPDATE appointments
    SET status = 'cancelled'
    WHERE doctor_id = p_doctor_id
      AND DATE(appointment_time) = p_date
      AND status = 'scheduled';

    RAISE NOTICE 'Cancelled % appointments for doctor % on %', v_count, p_doctor_id, p_date;
END;
$$;

CALL reschedule_appointment(2, '2026-05-10 14:00:00');
CALL reschedule_appointment(3, '2026-06-15 09:00:00');
CALL reschedule_appointment(2, '2020-01-01 10:00:00');
CALL reschedule_appointment(999, '2026-06-01 10:00:00');

CALL cancel_all_appointments(1, '2026-04-01');
CALL cancel_all_appointments(2, '2026-04-03');
CALL cancel_all_appointments(3, '2026-04-02');
CALL cancel_all_appointments(999, '2026-04-01');

SELECT * FROM appointments ORDER BY doctor_id, appointment_time;
