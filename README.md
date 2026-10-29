# PMO territorial · Colombia

Formulario público para recoger necesidades empresariales de toda Colombia. Cada envío solicita nombre del empresario, contacto, gremio, entidad, correo y necesidad, además de autorización para tratar los datos. El gremio es opcional.

- Sitio: https://pmo-territorial-colombia.vercel.app/
- Coordinación y destinatario: jose.gomez.lopez@colmayor.edu.co.
- Supabase: proyecto independiente PMO Territorial Colombia (`kwnsllunphcgdgmpkiuj`), tabla `pmo_iniciativas`.

El backend `pmo-submit` valida campos y consentimiento, limita solicitudes, guarda un UUID y no permite lectura pública. También acepta temporalmente el formato anterior para no interrumpir a quienes tuvieran abierta la versión previa. Los registros anteriores se conservan y los CSV incluyen sus campos junto con los nuevos. La tabla protege la consulta con RLS mediante el listado de administradores del proyecto. El panel privado usa el mismo correo de coordinación y Supabase Auth. Antes del primer acceso, el titular debe agregar la URL del sitio en Authentication → URL Configuration → Redirect URLs y abrir el enlace de inicio recibido en su correo.

El cron `pmo-daily-summary` prepara a las 07:00 hora de Colombia un CSV con todas las iniciativas recibidas el día anterior y lo envía desde la cuenta Gmail configurada al coordinador; días sin iniciativas no generan correo. Los registros técnicos están en `pmo_summary_runs`. Al usar SMTP, un error posterior a la aceptación puede dejar el estado incierto; revisar correo y logs antes de volver a enviar. El diseño de reserva evita reenvíos automáticos de días ya procesados, incluso si el estado es fallido; la recuperación requiere revisar y corregir el estado manualmente.

`backend/` contiene las funciones y migración. `GMAIL_APP_PASSWORD` y la credencial del cron se configuran como secretos propios del proyecto, nunca se incluyen en el repositorio. La política de tratamiento debe completarse por el responsable del proyecto antes de adaptar el formulario a otro uso o responsable.

El formulario no almacena respuestas sin conexión. Si el envío falla, las respuestas permanecen en el formulario mientras la página no se cierre. No incluye carga de documentos.
