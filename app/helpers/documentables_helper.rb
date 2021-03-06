module DocumentablesHelper

  def documentable_class(documentable)
    documentable.class.name.parameterize('_')
  end

  def max_documents_allowed(documentable)
    documentable.class.max_documents_allowed
  end

  def max_file_size(documentable)
    bytesToMeg(documentable.class.max_file_size)
  end

  def accepted_content_types(documentable)
    documentable.class.accepted_content_types
  end

  def accepted_content_types_extensions(documentable_class)
    documentable_class.accepted_content_types
                .collect{ |content_type| ".#{content_type.split("/").last}" }
                .join(",")
  end

  def humanized_accepted_content_types(documentable)
    documentable.class.accepted_content_types
                .collect{ |content_type| content_type.split("/").last }
                .join(", ")
  end

  def documentables_note(documentable)
    t "documents.form.note", max_documents_allowed: max_documents_allowed(documentable),
                             accepted_content_types: humanized_accepted_content_types(documentable),
                             max_file_size: max_file_size(documentable)
  end

  def max_documents_allowed?(documentable)
    documentable.documents.count >= documentable.class.max_documents_allowed
  end

end