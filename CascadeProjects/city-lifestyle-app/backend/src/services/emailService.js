const nodemailer = require('nodemailer');
const handlebars = require('handlebars');
const fs = require('fs').promises;
const path = require('path');

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    // Cache for email templates
    this.templateCache = new Map();
  }

  // Load and cache email template
  async loadTemplate(templateName) {
    if (this.templateCache.has(templateName)) {
      return this.templateCache.get(templateName);
    }

    const templatePath = path.join(__dirname, '../templates/emails', `${templateName}.hbs`);
    const templateContent = await fs.readFile(templatePath, 'utf-8');
    const template = handlebars.compile(templateContent);
    this.templateCache.set(templateName, template);
    return template;
  }

  // Send email using template
  async sendTemplateEmail(to, subject, templateName, data) {
    try {
      const template = await this.loadTemplate(templateName);
      const html = template(data);

      await this.transporter.sendMail({
        from: `"${process.env.EMAIL_FROM_NAME}" <${process.env.EMAIL_FROM_ADDRESS}>`,
        to,
        subject,
        html,
      });
    } catch (error) {
      console.error('Failed to send email:', error);
      throw new Error(`Failed to send email: ${error.message}`);
    }
  }

  // Send welcome email
  async sendWelcomeEmail(user) {
    await this.sendTemplateEmail(
      user.email,
      'Welcome to City Lifestyle!',
      'welcome',
      {
        name: user.name,
        verificationLink: `${process.env.CLIENT_URL}/verify-email?token=${user.emailVerificationToken}`,
      }
    );
  }

  // Send email verification
  async sendEmailVerification(user) {
    await this.sendTemplateEmail(
      user.email,
      'Verify Your Email',
      'email-verification',
      {
        name: user.name,
        verificationLink: `${process.env.CLIENT_URL}/verify-email?token=${user.emailVerificationToken}`,
      }
    );
  }

  // Send password reset email
  async sendPasswordReset(user) {
    await this.sendTemplateEmail(
      user.email,
      'Reset Your Password',
      'password-reset',
      {
        name: user.name,
        resetLink: `${process.env.CLIENT_URL}/reset-password?token=${user.passwordResetToken}`,
      }
    );
  }

  // Send event registration confirmation
  async sendEventRegistration(user, event) {
    await this.sendTemplateEmail(
      user.email,
      `Registration Confirmed: ${event.title}`,
      'event-registration',
      {
        name: user.name,
        eventTitle: event.title,
        eventDate: event.startDate.toLocaleDateString(),
        eventTime: event.startDate.toLocaleTimeString(),
        eventLocation: event.location.address,
        eventLink: `${process.env.CLIENT_URL}/events/${event._id}`,
      }
    );
  }

  // Send event reminder
  async sendEventReminder(user, event) {
    await this.sendTemplateEmail(
      user.email,
      `Reminder: ${event.title} starts in 24 hours`,
      'event-reminder',
      {
        name: user.name,
        eventTitle: event.title,
        eventDate: event.startDate.toLocaleDateString(),
        eventTime: event.startDate.toLocaleTimeString(),
        eventLocation: event.location.address,
        eventLink: `${process.env.CLIENT_URL}/events/${event._id}`,
      }
    );
  }

  // Send event cancellation notice
  async sendEventCancellation(user, event) {
    await this.sendTemplateEmail(
      user.email,
      `Event Cancelled: ${event.title}`,
      'event-cancellation',
      {
        name: user.name,
        eventTitle: event.title,
        eventDate: event.startDate.toLocaleDateString(),
        refundInfo: event.refundPolicy,
      }
    );
  }

  // Send waitlist promotion notification
  async sendWaitlistPromotion(user, event) {
    await this.sendTemplateEmail(
      user.email,
      `You're In! Spot Available for ${event.title}`,
      'waitlist-promotion',
      {
        name: user.name,
        eventTitle: event.title,
        eventDate: event.startDate.toLocaleDateString(),
        eventTime: event.startDate.toLocaleTimeString(),
        registrationDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000).toLocaleString(),
        eventLink: `${process.env.CLIENT_URL}/events/${event._id}`,
      }
    );
  }

  // Send review notification to place owner
  async sendReviewNotification(owner, place, review) {
    await this.sendTemplateEmail(
      owner.email,
      `New Review for ${place.name}`,
      'new-review',
      {
        ownerName: owner.name,
        placeName: place.name,
        reviewerName: review.user.name,
        rating: review.rating,
        comment: review.comment,
        placeLink: `${process.env.CLIENT_URL}/places/${place._id}`,
      }
    );
  }

  // Send weekly digest of recommendations
  async sendWeeklyDigest(user, recommendations) {
    await this.sendTemplateEmail(
      user.email,
      'Your Weekly City Lifestyle Digest',
      'weekly-digest',
      {
        name: user.name,
        events: recommendations.events,
        places: recommendations.places,
        preferencesLink: `${process.env.CLIENT_URL}/preferences`,
      }
    );
  }
}

module.exports = new EmailService();
