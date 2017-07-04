# This is a stand-in for an AREL Attribute. In the context of these tests,
# we need to verify the messages :eq, :in, :lteq, and :gteq.

class FakeArelAttribute
  def eq(value)
    [:eq, value]
  end

  def in(values)
    [:in, values]
  end

  def lteq(value)
    [:lteq, value]
  end

  def gteq(value)
    [:gteq, value]
  end
end
