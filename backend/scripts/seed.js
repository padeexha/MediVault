require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const HealthcareProvider = require('./models/HealthcareProvider');

// Sample Sri Lankan doctors used to populate a fresh database for testing and demos
const doctors = [
  {
    first_name: 'Priya',
    last_name: 'Ratnayake',
    email: 'priya.ratnayake@medivault.lk',
    specialization: 'Cardiology',
    organisation_name: 'National Hospital of Sri Lanka',
  },
  {
    first_name: 'Nuwan',
    last_name: 'Fernando',
    email: 'nuwan.fernando@medivault.lk',
    specialization: 'Pediatrics',
    organisation_name: 'Lady Ridgeway Hospital',
  },
  {
    first_name: 'Amali',
    last_name: 'Jayasinghe',
    email: 'amali.jayasinghe@medivault.lk',
    specialization: 'Gynecology & Obstetrics',
    organisation_name: 'De Soysa Hospital for Women',
  },
  {
    first_name: 'Kasun',
    last_name: 'Perera',
    email: 'kasun.perera@medivault.lk',
    specialization: 'Orthopedic Surgery',
    organisation_name: 'Teaching Hospital Kandy',
  },
  {
    first_name: 'Thilini',
    last_name: 'Wickramasinghe',
    email: 'thilini.wickramasinghe@medivault.lk',
    specialization: 'Dermatology',
    organisation_name: 'Nawaloka Hospital',
  },
  {
    first_name: 'Chamara',
    last_name: 'Silva',
    email: 'chamara.silva@medivault.lk',
    specialization: 'Neurology',
    organisation_name: 'Lanka Hospital',
  },
  {
    first_name: 'Sachini',
    last_name: 'Bandara',
    email: 'sachini.bandara@medivault.lk',
    specialization: 'Oncology',
    organisation_name: 'Asiri Central Hospital',
  },
  {
    first_name: 'Roshan',
    last_name: 'Dissanayake',
    email: 'roshan.dissanayake@medivault.lk',
    specialization: 'General Surgery',
    organisation_name: 'Durdans Hospital',
  },
  {
    first_name: 'Malini',
    last_name: 'Gunawardena',
    email: 'malini.gunawardena@medivault.lk',
    specialization: 'Endocrinology',
    organisation_name: 'Sri Jayewardenepura General Hospital',
  },
  {
    first_name: 'Dinesh',
    last_name: 'Seneviratne',
    email: 'dinesh.seneviratne@medivault.lk',
    specialization: 'Ophthalmology',
    organisation_name: 'Hemas Hospital Colombo',
  },
  {
    first_name: 'Nadeesha',
    last_name: 'Amarasinghe',
    email: 'nadeesha.amarasinghe@medivault.lk',
    specialization: 'Psychiatry',
    organisation_name: 'National Institute of Mental Health',
  },
  {
    first_name: 'Buddhika',
    last_name: 'Rajapaksa',
    email: 'buddhika.rajapaksa@medivault.lk',
    specialization: 'Nephrology',
    organisation_name: 'Teaching Hospital Karapitiya',
  },
  {
    first_name: 'Ishara',
    last_name: 'Madushanka',
    email: 'ishara.madushanka@medivault.lk',
    specialization: 'Pulmonology',
    organisation_name: 'Chest Hospital Welisara',
  },
  {
    first_name: 'Tharaka',
    last_name: 'Liyanage',
    email: 'tharaka.liyanage@medivault.lk',
    specialization: 'Gastroenterology',
    organisation_name: 'Apollo Hospital Colombo',
  },
  {
    first_name: 'Ruvini',
    last_name: 'Mendis',
    email: 'ruvini.mendis@medivault.lk',
    specialization: 'ENT (Ear, Nose & Throat)',
    organisation_name: 'Teaching Hospital Jaffna',
  },
];

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB');

    const defaultPassword = 'Doctor@123';

    let created = 0;
    let skipped = 0;

    for (const doc of doctors) {
      const exists = await User.findOne({ email: doc.email });
      if (exists) {
        console.log(`  skipped (already exists): ${doc.email}`);
        skipped++;
        continue;
      }

      // Pass raw password — the User pre('save') hook hashes it
      const user = await User.create({
        first_name: doc.first_name,
        last_name: doc.last_name,
        email: doc.email,
        password_hash: defaultPassword,
        role: 'doctor',
        isVerified: true,
      });

      await HealthcareProvider.create({
        user_id: user._id,
        specialization: doc.specialization,
        organisation_name: doc.organisation_name,
      });

      console.log(`  created: Dr. ${doc.first_name} ${doc.last_name} — ${doc.specialization} @ ${doc.organisation_name}`);
      created++;
    }

    console.log(`\nDone. ${created} doctors created, ${skipped} skipped.`);
    console.log(`Default password for all seeded doctors: ${defaultPassword}`);
  } catch (err) {
    console.error('Seed failed:', err.message);
  } finally {
    await mongoose.disconnect();
  }
}

seed();
