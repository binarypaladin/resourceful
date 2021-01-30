defprotocol Resourceful.Collection.Delegate do
  def cast_filter(data_source, filter)

  def cast_sorter(data_source, sorter)

  def collection(data_source)

  def filters(data_source)

  def paginate(data_source, number, size)

  def sort(data_source, sorters)
end
