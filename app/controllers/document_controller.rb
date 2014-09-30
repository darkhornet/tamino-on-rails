class DocumentController < ApplicationController
  
  def store
    if request.method == :post
      TAMINO.setHttpRequestMethod("POST")
      
      TAMINO.setCollection(@params["collection"])
      TAMINO.setEncoding(@params["encoding"])
      
      if TAMINO.process(@params["uploaded_file"].string)
        flash[:notice] = "Document stored successfully."
      else
        flash[:error] = "Document creation failed."
      end
      
    end
  end
  
  
  def delete
    if request.method == :post
      TAMINO.setHttpRequestMethod("POST")
      
      TAMINO.setCollection(@params["collection"])
      
      if TAMINO.delete(@params["document"])
        flash[:notice] = "Document deleted."
      else
        flash[:error] = "Document deletion failed."
      end
      
    end
  end  
  
  def query
    if request.method == :post
      TAMINO.setHttpRequestMethod("POST")
      
      TAMINO.setCollection(@params["collection"])
      
      if result = TAMINO.query(@params["query"])
      @result_xml = TAMINO.getResultDomNode.to_s
      else
        flash[:error] = "Query failed."
      end
      
    end
  end
end
