const express = require('express');
const router = express.Router();
const { protect, authorise } = require('../middleware/auth');
const MedicalRecord = require('../models/MedicalRecord');
const Patient = require('../models/Patient');

router.get('/', protect, authorise('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    const { title, category, date_from, date_to, sort_by } = req.query;

    const query = { patient_id: patient._id, is_deleted: false };
    if (title)    query.title    = { $regex: title, $options: 'i' };
    if (category) query.category = category;
    if (date_from || date_to) {
      query.upload_date = {};
      if (date_from) query.upload_date.$gte = new Date(date_from);
      if (date_to)   query.upload_date.$lte = new Date(date_to);
    }

    const sortOptions = {
      date_desc:  { upload_date: -1 },
      date_asc:   { upload_date:  1 },
      title_asc:  { title:  1 },
      title_desc: { title: -1 },
    };
    const sortOption = sortOptions[sort_by] || sortOptions.date_desc;

    const records = await MedicalRecord.find(query).sort(sortOption);
    res.status(200).json({ success: true, count: records.length, records });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;