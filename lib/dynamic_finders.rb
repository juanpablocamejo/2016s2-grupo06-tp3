module DynamicFinders
  def method_missing(sel, *args)
    a_filter=find_filter(sel, args)
    if (a_filter.nil?)
      super
    else
      find(a_filter)
    end
  end

  def find_filter(sel, args)
    if !sel.to_s.start_with?('find_by_') then
      nil
    end
    s_fields = sel_fields sel
    if !valid_fields?(s_fields)
      nil
    else
      (s_fields.zip args).to_h
    end
  end

  def sel_fields(sel)
    str=sel.to_s.sub('find_by_', '')
    str.split('_and_').map { |s| s==='id' ? '_id' : s }
  end

  def valid_fields?(sel_fields)
    (sel_fields - self.fields.map { |sym| sym.to_s }).empty?
  end
end