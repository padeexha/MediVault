const mongoose = require('mongoose');

// Append-only style log for important data-access events.
// References are nullable so login or failed actions can be recorded even without a record/permission.
const auditLogSchema = new mongoose.Schema({
  patient_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    default: null,
  },
  actor_user_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  // Both nullable — not every event involves a record or a permission change
  record_id:     { type: mongoose.Schema.Types.ObjectId, ref: 'MedicalRecord',    default: null },
  permission_id: { type: mongoose.Schema.Types.ObjectId, ref: 'AccessPermission', default: null },

  action_type: {
    type: String,
    enum: [
      'upload', 'view', 'download', 'delete', 'edit',
      'permission_granted', 'permission_revoked', 'permission_updated',
      'login', 'logout', 'password_reset',
    ],
    required: true,
  },
  action_status: {
    type: String,
    enum: ['success', 'failure'],
    default: 'success',
  },
  action_date: { type: Date, default: Date.now },
  details:     { type: String },
  ip_address:  { type: String },
}, { timestamps: true });

module.exports = mongoose.model('AuditLog', auditLogSchema);
