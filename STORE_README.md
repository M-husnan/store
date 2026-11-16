# Store section

The Store replaces the Courses tab in the Flutter app. Its first screen starts
with a search bar that searches products across every category. Customers can
browse Skin Care, Detergents, Kitchen Essentials, and Bakery, then browse
subcategories and products, build a cart, submit an order, and download a PDF
invoice. Product cards show the price and unit, with quantity controls for the
cart. A shared sort menu applies in product sections and search results, with
recommended order, price low-to-high, price high-to-low, and name A-to-Z or
Z-to-A options.

Online payment is not part of checkout. The customer pays at the store. For a
phone order, the customer can enter a callback number; the store contact button
calls **+923280067054**.

## Add the products later

Deploy the project so the new database migration runs (`python manage.py migrate`;
the included Render `build.sh` runs migrations automatically). Open Django admin
and use **Store categories**, **Store subcategories**, and **Store products**:

1. The four requested categories and starter subcategories are created the first
   time the Store catalog is opened. Skin Care includes Cosmetics and Soaps.
   Kitchen Essentials includes Masala, Ghee and Oil, and Rice.
2. Add or edit subcategories under each category.
3. Add each product under its subcategory. Set its price in PKR, unit (for
   example `1 kg` or `500 ml`), optional description and image URL, and stock
   status. Inactive or out-of-stock items are hidden from customers.
4. Orders and their item/price snapshots appear under **Store orders** in admin.

Prices and totals are recalculated on the server when the order is submitted.
Each order gets an invoice number and an owner-only PDF invoice endpoint.

## Friends and groups

The profile page shows profile details in icon cards and includes Friends and
Find friends actions. Search lets a user follow an account; the Friends page
lists mutual follows. Status privacy already uses mutual follows for the
Friends-only option. Creating a group displays searchable matches from the
user's phone contacts. The phone book stays on the device; only people whose
accounts have phone discovery enabled can be selected. Phone discovery is on
by default and can be disabled in privacy settings.

Find Friends opens a paginated directory of active store accounts. Search
matches usernames, first and last names, email addresses, and discoverable
mobile numbers; email addresses and phone numbers are not included in search
results. The profile editor selects Pakistan's `+92` code by default and adds
it to a local mobile number entered beginning with `3`.

## Feed, contacts, and profile privacy

New feed posts use **Store update** as their default title. Sharing another
person's post embeds the complete post contents without an "Original post"
label. On Android and iOS, the chat list can show the saved phone-contact name
for a matching account after the user grants contact access. Phone discovery is
enabled by default; adding a phone number makes the account matchable. A group
can be created with one selected contact plus its creator.

Only the account owner and their mutual-follow friends receive a user's phone
number, address, bio, profile and cover photos, and friends list through the
app or profile page. Run `python manage.py migrate` to apply the new default
phone-discovery migration.
