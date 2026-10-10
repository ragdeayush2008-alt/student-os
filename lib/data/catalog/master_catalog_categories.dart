import 'package:flutter/material.dart';
import '../models/catalog/catalog_category.dart';

/// Authoritative definitions for the 18 Master Categories in Student OS Catalog 2.0.
abstract final class MasterCatalogCategories {
  static const school = CatalogCategory2(
    id: 'school_boards_olympiads',
    title: 'School, Boards & Olympiads',
    shortTitle: 'School & Boards',
    description: 'Classes 1–12, CBSE, ICSE, State Boards & School Olympiads',
    iconData: Icons.school_rounded,
    order: 1,
    isPopular: true,
  );

  static const engineering = CatalogCategory2(
    id: 'engineering_technology',
    title: 'Engineering & Technology',
    shortTitle: 'Engineering & JEE',
    description: 'JEE Main, JEE Advanced, GATE, MHT-CET & State Engineering Entrances',
    iconData: Icons.engineering_rounded,
    order: 2,
    isPopular: true,
  );

  static const medical = CatalogCategory2(
    id: 'medical_healthcare',
    title: 'Medical & Healthcare',
    shortTitle: 'Medical & NEET',
    description: 'NEET UG, NEET PG, Nursing, Pharmacy & Allied Healthcare Entrances',
    iconData: Icons.medical_services_rounded,
    order: 3,
    isPopular: true,
  );

  static const commerceFinance = CatalogCategory2(
    id: 'commerce_accounting_finance',
    title: 'Commerce, Accounting & Finance',
    shortTitle: 'CA, CS & Finance',
    description: 'CA 2026, CS, CMA, CFA 2026, ACCA, FRM & Actuarial Sciences',
    iconData: Icons.account_balance_rounded,
    order: 4,
    isPopular: true,
  );

  static const governmentJobs = CatalogCategory2(
    id: 'government_job_exams',
    title: 'Government Job Exams',
    shortTitle: 'Govt Jobs & UPSC/SSC',
    description: 'UPSC Civil Services, SSC CGL/CHSL/MTS, Railways & State PSC',
    iconData: Icons.account_balance_outlined,
    order: 5,
    isPopular: true,
  );

  static const banking = CatalogCategory2(
    id: 'banking_financial_recruitment',
    title: 'Banking & Financial Recruitment',
    shortTitle: 'Banking & Insurance',
    description: 'IBPS PO/Clerk, SBI PO/Clerk, RBI Grade B, SEBI & NABARD',
    iconData: Icons.payments_rounded,
    order: 6,
    isPopular: true,
  );

  static const management = CatalogCategory2(
    id: 'management_business',
    title: 'Management & Business',
    shortTitle: 'MBA & CAT',
    description: 'CAT, XAT, SNAP, CMAT, MAT, NMAT & MAH MBA CET',
    iconData: Icons.business_center_rounded,
    order: 7,
    isPopular: true,
  );

  static const law = CatalogCategory2(
    id: 'law',
    title: 'Law & Judiciary',
    shortTitle: 'Law & CLAT',
    description: 'CLAT UG, CLAT PG, AILET, SLAT & State Judiciary / Civil Judge Exams',
    iconData: Icons.gavel_rounded,
    order: 8,
    isPopular: true,
  );

  static const universityEntrance = CatalogCategory2(
    id: 'science_university_entrance',
    title: 'Science & University Entrance',
    shortTitle: 'CUET & UG Entrance',
    description: 'CUET UG (Languages, Domains, General Test) & University Entrances',
    iconData: Icons.science_rounded,
    order: 9,
    isPopular: true,
  );

  static const teaching = CatalogCategory2(
    id: 'teaching_education',
    title: 'Teaching & Education',
    shortTitle: 'Teaching & TET',
    description: 'CTET, State TETs, KVS, NVS & Teacher Recruitment Examinations',
    iconData: Icons.menu_book_rounded,
    order: 10,
    isPopular: false,
  );

  static const research = CatalogCategory2(
    id: 'research_net_exams',
    title: 'Research & NET Exams',
    shortTitle: 'UGC NET & Research',
    description: 'UGC NET (all 80+ subjects), CSIR NET & SET State Eligibility',
    iconData: Icons.biotech_rounded,
    order: 11,
    isPopular: false,
  );

  static const defence = CatalogCategory2(
    id: 'defence',
    title: 'Defence & Armed Forces',
    shortTitle: 'Defence (NDA/CDS)',
    description: 'NDA, CDS, AFCAT, CAPF & Agniveer Armed Forces Recruitment',
    iconData: Icons.shield_rounded,
    order: 12,
    isPopular: false,
  );

  static const design = CatalogCategory2(
    id: 'design',
    title: 'Design & Creative Arts',
    shortTitle: 'Design (NID/UCEED)',
    description: 'UCEED, CEED, NID DAT, NIFT & B.Des Design Entrances',
    iconData: Icons.palette_rounded,
    order: 13,
    isPopular: false,
  );

  static const architecture = CatalogCategory2(
    id: 'architecture_planning',
    title: 'Architecture & Planning',
    shortTitle: 'Architecture (NATA)',
    description: 'NATA, JEE Main Paper 2 & B.Arch / B.Planning Programs',
    iconData: Icons.apartment_rounded,
    order: 14,
    isPopular: false,
  );

  static const agriculture = CatalogCategory2(
    id: 'agriculture',
    title: 'Agriculture & Allied Sciences',
    shortTitle: 'Agriculture & ICAR',
    description: 'ICAR AIEEA, State Agriculture Entrances & BSc Agriculture',
    iconData: Icons.agriculture_rounded,
    order: 15,
    isPopular: false,
  );

  static const postgraduate = CatalogCategory2(
    id: 'postgraduate_entrance',
    title: 'Postgraduate Entrance',
    shortTitle: 'PG Entrances',
    description: 'CUET PG, MAH MCA CET, IIT JAM & University PG Programs',
    iconData: Icons.psychology_rounded,
    order: 16,
    isPopular: false,
  );

  static const professionalCerts = CatalogCategory2(
    id: 'professional_certifications',
    title: 'Professional Certifications',
    shortTitle: 'Certifications',
    description: 'Industry Recognized Credentials, Cloud, Data & IT Certifications',
    iconData: Icons.verified_rounded,
    order: 17,
    isPopular: false,
  );

  static const otherCareer = CatalogCategory2(
    id: 'other_career_upskilling',
    title: 'Other Career & Upskilling Paths',
    shortTitle: 'Skills & Career',
    description: 'General Aptitude, Professional Skills & Lifelong Learning',
    iconData: Icons.auto_awesome_rounded,
    order: 18,
    isPopular: false,
  );

  /// All 18 categories ordered.
  static List<CatalogCategory2> getAllCategories() => [
    school,
    engineering,
    medical,
    commerceFinance,
    governmentJobs,
    banking,
    management,
    law,
    universityEntrance,
    teaching,
    research,
    defence,
    design,
    architecture,
    agriculture,
    postgraduate,
    professionalCerts,
    otherCareer,
  ];
}
