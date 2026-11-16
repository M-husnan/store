from django.db import migrations, models


def enable_default_phone_discovery(apps, schema_editor):
    Profile = apps.get_model('home', 'Profile')
    Profile.objects.update(phone_discoverable=True)


class Migration(migrations.Migration):
    dependencies = [('home', '0037_friends_only_status_privacy')]

    operations = [
        migrations.RunPython(enable_default_phone_discovery, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='profile',
            name='phone_discoverable',
            field=models.BooleanField(default=True),
        ),
    ]
