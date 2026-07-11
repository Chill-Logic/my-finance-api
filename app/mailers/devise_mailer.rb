class DeviseMailer < Devise::Mailer
  before_action :attach_logo

  private

  def attach_logo
    attachments.inline['logo.png'] = File.read(Rails.root.join('app/assets/images/logo_myfinance.png'))
  end
end
