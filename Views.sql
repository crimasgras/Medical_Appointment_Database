
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



CREATE VIEW upcoming_appointments AS
SELECT 
    a.appointment_id,
    d.first_name || ' ' || d.last_name AS doctor,
    p.first_name || ' ' || p.last_name AS patient,
    a.appointment_time
FROM appointments a
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN patients p ON a.patient_id = p.patient_id
WHERE a.status = 'scheduled'
AND a.appointment_time > CURRENT_TIMESTAMP
ORDER BY a.appointment_time;


CREATE VIEW doctor_appointment_summary AS
SELECT
    d.first_name || ' ' || d.last_name AS doctor,
    COUNT(a.appointment_id) AS total,
    SUM(CASE WHEN a.status = 'scheduled'  THEN 1 ELSE 0 END) AS scheduled,
    SUM(CASE WHEN a.status = 'completed'  THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN a.status = 'cancelled'  THEN 1 ELSE 0 END) AS cancelled
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name;
