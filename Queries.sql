
SELECT schedule_appointment(1, 1, '2026-03-06 10:00:00');


SELECT schedule_appointment(2, 1, '2026-03-06 10:00:00');


SELECT schedule_appointment(1, 1, '2020-01-01 09:00:00');


UPDATE appointments
SET status = 'completed'
WHERE appointment_id = 1;


SELECT * FROM doctor_schedule;


SELECT * FROM upcoming_appointments;


SELECT * FROM doctor_appointment_summary;

SELECT 
    d.doctor_id,
    d.first_name,
    d.last_name,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY total_appointments DESC;

SELECT
    d.doctor_id,
    d.first_name || ' ' || d.last_name AS doctor,
    a.status,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name, a.status
ORDER BY doctor, total_appointments DESC;


SELECT
    DATE(appointment_time) AS appointment_day,
    COUNT(*) AS total_appointments
FROM appointments
GROUP BY DATE(appointment_time)
ORDER BY total_appointments DESC, appointment_day ASC;

SELECT * FROM appointment_audit
ORDER BY audit_id DESC;

SELECT cancel_appointment(1);

SELECT * FROM get_doctor_appointments(1);

SELECT * FROM get_available_doctors('2026-03-06 10:00:00');
