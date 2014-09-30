class SchemaController < ApplicationController
  
  
  def define
    if request.method == :post
      TAMINO.setHttpRequestMethod("POST")
      if TAMINO.define(@params["uploaded_file"].string)
        flash[:notice] = "Schema created successfully."
      else
        flash[:error] = "Schema creation failed."
      end
      
    end
  end
  def undefine
    if request.method == :post
      TAMINO.setHttpRequestMethod("POST")
      if TAMINO.undefine(@params["name"])
        flash[:notice] = "Schema deleted successfully."
      else
        flash[:error] = "Schema deletion failed."
      end
      
    end
  end
end
