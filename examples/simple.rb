class Task < ActiveRecord::Base
  # Assume this model has attributes: :id, :due_date, and :name
end

class TaskSearch < SearchLingo::AbstractSearch
  parser SearchLingo::Parsers::DateParser.new :tasks,
    :due_date
  parser SearchLingo::Parsers::DateRangeParser.new :tasks,
    :due_date
  parser SearchLingo::Parsers::LTEDateParser.new :tasks,
    :due_date, connection: ActiveRecord::Base.connection
  parser SearchLingo::Parsers::GTEDateParser.new :tasks,
    :due_date, connection: ActiveRecord::Base.connection

  parser do |token|
    token.match /\Aid:\s*([[:digit:]]+)\z/ do |m|
      [:where, { tasks: { id: m[1] } }]
    end
  end

  def default_parse(token)
    [:where, 'tasks.name LIKE ?', "%#{token}%"]
  end
end

search = TaskSearch.new('6/4/15 id: 42 foo "bar baz"', Task)
search.results  # =>  Task
                #       .where(tasks: { due_date: Date.new(2015, 6, 4) })
                #       .where(tasks: { id: '42' })
                #       .where('tasks.name LIKE ?', '%foo%')
                #       .where('tasks.name LIKE ?', '%bar baz%')
