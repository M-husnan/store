from django.contrib import admin
from .models import Event
from .models import Venue
from .models import MyClubUser, Category, Comment
from .models import Profile, Meep, Complaint, Video, PostReport
from .models import StoreCategory, StoreSubcategory, StoreProduct, StoreOrder, StoreOrderItem
from django.contrib.auth.models import User, Group

admin.site.unregister (Group)
admin.site.register(Profile)
admin.site.register(MyClubUser)
@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'user', 'date', 'status')
    list_filter = ('status', 'date')
    search_fields = ('name', 'email', 'desc', 'user__username')
    readonly_fields = ('user', 'date')
admin.site.register(Category)
admin.site.register(Video)
admin.site.register(Comment)

@admin.register(PostReport)
class PostReportAdmin(admin.ModelAdmin):
    list_display = ('id', 'post', 'reporter', 'reason', 'status', 'created_at')
    list_filter = ('status', 'reason', 'created_at')
    search_fields = ('post__title', 'post__user__username', 'reporter__username', 'details')
    readonly_fields = ('post', 'reporter', 'reason', 'details', 'created_at')

class ProfileInline(admin.StackedInline):
    model = Profile


class UserAdmin(admin.ModelAdmin):
    model = User    
    fields = ['username']
    inlines = [ProfileInline]

admin.site.unregister (User)   
admin.site.register(User, UserAdmin)
admin.site.register(Meep)


@admin.register(StoreCategory)
class StoreCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'sort_order', 'active')
    list_editable = ('sort_order', 'active')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name',)


@admin.register(StoreSubcategory)
class StoreSubcategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'sort_order', 'active')
    list_filter = ('category', 'active')
    list_editable = ('sort_order', 'active')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name', 'category__name')


@admin.register(StoreProduct)
class StoreProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'subcategory', 'price', 'unit', 'in_stock', 'active')
    list_filter = ('subcategory__category', 'subcategory', 'in_stock', 'active')
    list_editable = ('price', 'in_stock', 'active')
    search_fields = ('name', 'description')


class StoreOrderItemInline(admin.TabularInline):
    model = StoreOrderItem
    extra = 0
    readonly_fields = ('product', 'product_name', 'unit', 'unit_price', 'quantity', 'line_total')


@admin.register(StoreOrder)
class StoreOrderAdmin(admin.ModelAdmin):
    list_display = ('invoice_number', 'user', 'fulfillment', 'total', 'status', 'created_at')
    list_filter = ('status', 'fulfillment', 'created_at')
    search_fields = ('invoice_number', 'user__username', 'contact_phone')
    readonly_fields = ('user', 'invoice_number', 'fulfillment', 'contact_phone', 'total', 'created_at')
    inlines = [StoreOrderItemInline]
   


@admin.register(Venue)
class VenueAdmin(admin.ModelAdmin):
    list_display = ("name", "address", "phone")
    ordering = ("name",)
    search_fields = ("name", "address")

@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    fields = (("name", "venue"), 'event_date', 'description', 'manager' )
    list_display = ('name', "event_date", "venue") 
    list_filter = ('event_date', 'venue')
    ordering = ('-event_date',)

