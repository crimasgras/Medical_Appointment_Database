-- Table storing patient information.
-- Each patient represents a person who can schedule medical appointments.
-- A patient can have multiple appointments with different doctors.


CREATE TYPE appointment_status AS ENUM ('scheduled', 'cancelled', 'completed');

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY, 
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE doctors (
    doctor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE specialties (
    specialty_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Many-to-many relationship between doctors and specialties
CREATE TABLE doctor_specialties (
    doctor_id INT NOT NULL,
    specialty_id INT NOT NULL,
    PRIMARY KEY (doctor_id, specialty_id), -- composite key
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id)
);

-- Appointments table connecting patients and doctors
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_time TIMESTAMP NOT NULL,
    status appointment_status DEFAULT 'scheduled',
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

-- Audit table to track appointment changes
CREATE TABLE appointment_audit (
    audit_id SERIAL PRIMARY KEY,
    appointment_id INT NOT NULL,
    action VARCHAR(20) NOT NULL,
    action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Prevent double booking for the same doctor at the same time
ALTER TABLE appointments
ADD CONSTRAINT uq_doctor_time UNIQUE (doctor_id, appointment_time);

-- Index to improve query performance when searching by doctor and time
CREATE INDEX idx_appointments_doctor_time
ON appointments (doctor_id, appointment_time);


INSERT INTO patients(first_name, last_name, email) VALUES
('Ana', 'Pop', 'ana@test.com'),
('Mihai', 'Ionescu', 'mihai@test.com');

INSERT INTO doctors(first_name, last_name, email) VALUES
('Ioan', 'Marin', 'doc@test.com');

INSERT INTO specialties(name) VALUES
('Cardiology'),
('Neurology');

INSERT INTO doctor_specialties(doctor_id, specialty_id) VALUES
(1, 1),
(1, 2);

INSERT INTO appointments(patient_id, doctor_id, appointment_time)
VALUES (1, 1, '2026-03-05 10:00:00');

-- Second appointment at the same time for the same doctor
-- This should fail due to the UNIQUE constraint
-- INSERT INTO appointments(patient_id, doctor_id, appointment_time)
-- VALUES (2, 1, '2026-03-05 10:00:00');


CREATE OR REPLACE FUNCTION schedule_appointment(
    p_patient_id INT,
    p_doctor_id INT,
    p_time TIMESTAMP
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN

    -- Prevent scheduling appointments in the past
    IF p_time < CURRENT_TIMESTAMP THEN
        RETURN 'Appointment time must be in the future';
    END IF;

    INSERT INTO appointments(patient_id, doctor_id, appointment_time)
    VALUES (p_patient_id, p_doctor_id, p_time);

    RETURN 'Appointment scheduled';

EXCEPTION
    -- Handle double booking
    WHEN unique_violation THEN
        RETURN 'This time slot is already booked';

    -- Handle invalid patient or doctor
    WHEN foreign_key_violation THEN
        RETURN 'Invalid patient or doctor id';
END;
$$;


-- Function used by trigger to log INSERT actions
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


-- Function used by trigger to log UPDATE actions
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

-- Function to cancel a scheduled appointment
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



-- Trigger to automatically log appointment creation
CREATE TRIGGER trg_log_appointment_insert
AFTER INSERT ON appointments
FOR EACH ROW
EXECUTE FUNCTION log_appointment_insert();

-- Trigger to automatically log appointment updates
CREATE TRIGGER trg_log_appointment_update
AFTER UPDATE ON appointments
FOR EACH ROW
EXECUTE FUNCTION log_appointment_update();

CREATE VIEW doctor_schedule AS
SELECT 
    a.appointment_id,
    d.first_name || ' ' || d.last_name AS doctor,
    p.first_name || ' ' || p.last_name AS patient,
    a.appointment_time,
    a.status
FROM appointments a
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN patients p ON a.patient_id = p.patient_id;

-- Successful appointment
SELECT schedule_appointment(1, 1, '2026-03-06 10:00:00');

-- Attempt double booking
SELECT schedule_appointment(2, 1, '2026-03-06 10:00:00');

-- Attempt appointment in the past
SELECT schedule_appointment(1, 1, '2020-01-01 09:00:00');

-- Update appointment status
UPDATE appointments
SET status = 'completed'
WHERE appointment_id = 1;

-- Display doctor schedule
SELECT * FROM doctor_schedule;

-- Total appointments per doctor
SELECT 
    d.doctor_id,
    d.first_name,
    d.last_name,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a 
    ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY total_appointments DESC;

--Appointments by doctor and status
SELECT
    d.doctor_id,
    d.first_name || ' ' || d.last_name AS doctor,
    a.status,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name, a.status
ORDER BY doctor, total_appointments DESC;

-- Busiest appointment days
SELECT
    DATE(appointment_time) AS appointment_day,
    COUNT(*) AS total_appointments
FROM appointments
GROUP BY DATE(appointment_time)
ORDER BY total_appointments DESC, appointment_day ASC;


SELECT * FROM appointment_audit
ORDER BY audit_id DESC;

-- Cancel an appointment
SELECT cancel_appointment(1);

