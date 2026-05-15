const express = require('express');
const router = express.Router();
const { protect, authorise } = require('../middleware/auth');
const MedicalRecord = require('../models/MedicalRecord');
const Patient = require('../models/Patient');

const escapeRegex = (str) => str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

router.get('/', protect, authorise('patient'), async (req, res) => {
  try {
    // Resolve the logged-in user to their Patient document before querying records.
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    const { title, category, date_from, date_to, sort_by } = req.query;

    // Base MongoDB filter keeps search results scoped to this patient and hides soft-deleted records.
    const query = { patient_id: patient._id, is_deleted: false };
    if (title)    query.title    = { $regex: escapeRegex(title), $options: 'i' };
    if (category) query.category = category;
    if (date_from || date_to) {
      const from = date_from ? new Date(date_from) : null;
      const to   = date_to   ? new Date(date_to)   : null;
      if ((from && isNaN(from)) || (to && isNaN(to))) {
        return res.status(400).json({ success: false, message: 'Invalid date format' });
      }
      query.upload_date = {};
      if (from) query.upload_date.$gte = from;
      if (to)   query.upload_date.$lte = to;
    }

    const sortOptions = {
      date_desc:  { upload_date: -1 },
      date_asc:   { upload_date:  1 },
      title_asc:  { title:  1 },
      title_desc: { title: -1 },
    };
    const sortOption = sortOptions[sort_by] || sortOptions.date_desc;

    // Execute the assembled filter with the requested sort order.
    const records = await MedicalRecord.find(query).sort(sortOption);
    res.status(200).json({ success: true, count: records.length, records });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
