class <%= migration_name %> < ActiveRecord::Migration
<%
  def options_from_table_column col
    str = [":#{col.type}"] 
    str << ":default => #{col.default}" unless col.default.nil?
    str << ":null => false " unless col.null
    str << ":limit => #{col.limit}" unless col.limit.nil?
    str << ":precision => #{col.precision}" unless col.precision.nil?
    str << ":scale => #{col.scale}" unless col.scale.nil?
    str << ":primary => true" if col.primary
    str.join(', ')
  end

  def options_from_target_column hash
    hash.map{|el| el[0]=":#{el[0]}"; el * " => "} * ", " 
  end
%>
  def self.up
    <% removed_columns.each_pair do |col, col_info| %>
      remove_column :<%=table_name%>, :<%=col%>
    <% end %>

    <% added_columns.each_pair do |col, col_info| %>
      add_column :<%=table_name%>, :<%=col%>, :<%=col_info[1]%>, <%= options_from_target_column col_info[2] %>
    <% end %>

    <% changed_columns.each_pair do |col, col_info| %>
      change_column :<%=table_name%>, :<%=col%>, :<%=col_info[0][1]%>, <%= options_from_target_column col_info[0][2]%>
    <% end %>
  end
  
  def self.down
    <% removed_columns.each do |col, col_info| %>
      add_column :<%=table_name.to_sym%>, :<%= col%>, <%= options_from_table_column col_info%> 
    <% end %>

    <% added_columns.each_pair do |col, col_info| %>
      remove_column :<%=table_name%>, :<%=col%>
    <% end %>

    <% changed_columns.each_pair do |col, col_info| %>
      change_column :<%=table_name%>, :<%=col%>, <%= options_from_table_column col_info[1]%>
    <% end %>
  end

end
