defprotocol Resourceful.Collection.Delegate do
  def collection(data_source)

  def filter(data_source)

  def paginate(data_source, page, per)

  def sort(data_source, sorters)
end
