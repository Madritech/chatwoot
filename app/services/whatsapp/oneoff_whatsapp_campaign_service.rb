class Whatsapp::OneoffWhatsappCampaignService
  pattr_initialize [:campaign!]

  def perform
    Rails.logger.info("[WHATSAPP_CAMPAIGN] Ejecutando campaña #{campaign.id} - #{campaign.title}")

    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Whatsapp' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    campaign.completed!
    Rails.logger.info("[WHATSAPP_CAMPAIGN] Campaña marcada como completada")

    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)

    Rails.logger.info("[WHATSAPP_CAMPAIGN] Labels aplicadas a la audiencia: #{audience_labels.join(', ')}")

    process_audience(audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    Rails.logger.info("[WHATSAPP_CAMPAIGN] Contactos encontrados: #{contacts.count}")

    contacts.each do |contact|
      if contact.phone_number.blank?
        Rails.logger.warn("[WHATSAPP_CAMPAIGN] Contacto #{contact.id} sin número de teléfono, omitiendo...")
        next
      end

      Rails.logger.info("[WHATSAPP_CAMPAIGN] Enviando a #{contact.phone_number} (contact_id: #{contact.id})")
      send_message(to: contact.phone_number, content: campaign.message)
    end
  end

  def send_message(to:, content:)
    Rails.logger.info("[WHATSAPP_CAMPAIGN] Hernann")
    Rails.logger.info("[WHATSAPP_CAMPAIGN] To: #{to}, content: #{content}")
    template_name, lang_code, parameters = parse_template_content(content)

    Rails.logger.info("[WHATSAPP_CAMPAIGN] Template: #{template_name}, Lang: #{lang_code}, Params: #{parameters}")

    channel.send_template(to, {
      name: template_name,
      lang_code: lang_code,
      parameters: parameters
    })
  end

  def parse_template_content(content)
    return [nil, nil, []] if content.blank?

    # Split por "::" para separar template y lenguaje
    template_name, lang_code_and_params = content.to_s.split('::', 2)
    return [nil, nil, []] if template_name.blank? || lang_code_and_params.blank?

    # Ahora split por ":" para ver si hay parámetros
    lang_code, param_string = lang_code_and_params.split(':', 2)

    parameters = param_string.to_s.split('|')
    [template_name, lang_code, parameters]
  end

end
