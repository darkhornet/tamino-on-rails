class PersonController < ApplicationController
  
  def list
    @people = Person.find(:all)
  end
  
  def show
    @person = Person.find(params[:id])
  end
  
  def edit
    @person = Person.find(params[:id])
    
    if request.method == :post
      @person.name.firstName = params[:firstname]
      @person.name.lastName = params[:lastname]
      @person.address.street.name = params[:streetname]
      @person.address.street.number = params[:streetnumber]
      @person.address.city = params[:city]
      
      @person.save!
      flash[:notice] = "Record was updated."
      redirect_to :action => "list"
    end
    
  end
  
  def create
    
    
    case request.method
    when :get
      @person = Person.new
      render :action => "edit"
    when :post
      @person = Person.create :name => {:firstName => params[:firstname], 
							:lastName => params[:lastname]},
					:address => {:street => {:name => params[:streetname], 
							:number => params[:streetnumber]}, 
					:city => params[:city]}
      flash[:notice] = "Record created."
      redirect_to :action => "list"
    end
    
  end
  
  def delete
    @person = Person.delete(params[:id])
    flash[:notice] = "Record was deleted."
    redirect_to :action => "list"
  end
end
