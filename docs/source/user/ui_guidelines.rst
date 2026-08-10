The dSIPRouter GUI follows specific design principles to ensure a consistent and user-friendly experience. When creating custom modules with user interfaces, adhere to the following guidelines:

1. Consistent Layout
------------------------
Use the existing layout structure of dSIPRouter as a reference. Ensure that your module's pages maintain a consistent header, footer, and navigation menu. This helps users feel familiar with the interface.

The UI uses the Python Flask framework with Jinja2 templating. Leverage these technologies to create dynamic and reusable components.
There are base templates available in the main application that you can extend for your module's pages.

The primary template is called templates/table_layout.html. This template includes common elements such as the header, footer, and navigation menu. Extend this template in your module's templates to maintain consistency.
That template has a number of blocks that can be overridden to customize the content of your module's pages.  The blocks are visually represented below
.. image:: ../_static/images/ui_blocks.png
   :alt: UI Blocks
   :align: center   

2. The table layout template has the following blocks that can be overridden:
 - title: The title of the page, displayed in the browser tab.
 - table_headers: The headers for the main table on the page.
 - table: The rows of data for the main table on the page.
 - add_modal: The modal dialog for adding new entries.
 - edit_modal: The modal dialog for editing existing entries.
 - delete_modal: The modal dialog for deleting entries.
 - import_modal: The modal dialog for importing entries.
 