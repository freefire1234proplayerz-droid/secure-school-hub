import { query } from '../db.js';

export async function logAudit({
  req,
  actorUserId,
  targetUserId = null,
  targetStudentId = null,
  action,
  category,
  detail = null,
  metadata = {},
}) {
  try {
    const actor = actorUserId ?? req?.user?.id ?? req?.user?.sub ?? null;
    await query(
      `INSERT INTO audit_logs (
         actor_user_id,
         target_user_id,
         target_student_id,
         action,
         category,
         detail,
         metadata,
         ip_address,
         user_agent
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9)`,
      [
        actor,
        targetUserId,
        targetStudentId,
        action,
        category,
        detail,
        JSON.stringify(metadata ?? {}),
        req?.ip ?? null,
        req?.headers?.['user-agent'] ?? null,
      ],
    );
  } catch (error) {
    // Audit logging should not break the workflow it is observing.
    // eslint-disable-next-line no-console
    console.warn('Audit log write failed:', error.message);
  }
}
