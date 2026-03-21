CREATE OR REPLACE FUNCTION schedule_appointment(
    p_patient_id INT,
    p_doctor_id INT,
    p_time TIMESTAMP
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_time < CURRENT_TIMESTAMP THEN
        RETURN 'Appointment time must be in the future';
    END IF;

    INSERT INTO appointments(patient_id, doctor_id, appointment_time)
    VALUES (p_patient_id, p_doctor_id, p_time);

    RETURN 'Appointment scheduled';

EXCEPTION
    WHEN unique_violation THEN
        RETURN 'This time slot is already booked';
    WHEN foreign_key_violation THEN
        RETURN 'Invalid patient or doctor id';
END;
$$;


CREATE OR REPLACE FUNCTION cancel_appointment(p_appointment_id INT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE appointments
    SET status = 'cancelled'
    WHERE appointment_id = p_appointment_id
      AND status = 'scheduled';

    IF NOT FOUND THEN
        RETURN 'Appointment not found or already cancelled';
    END IF;

    RETURN 'Appointment cancelled successfully';
END;
$$;


CREATE OR REPLACE FUNCTION get_doctor_appointments(p_doctor_id INT)
RETURNS TABLE (
    patient_name TEXT,
    appointment_time TIMESTAMP,
    status appointment_status
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.first_name || ' ' || p.last_name,
        a.appointment_time,
        a.status
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE a.doctor_id = p_doctor_id
    ORDER BY a.appointment_time;
END;
$$;


CREATE OR REPLACE FUNCTION get_available_doctors(p_time TIMESTAMP)
RETURNS TABLE (doctor_name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT d.first_name || ' ' || d.last_name
    FROM doctors d
    WHERE d.doctor_id NOT IN (
        SELECT doctor_id FROM appointments
        WHERE appointment_time = p_time
        AND status = 'scheduled'
    );
END;
$$;
