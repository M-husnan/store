from django import template

register = template.Library()


@register.filter
def can_view_private_profile(person, viewer):
    """Return whether the viewer owns or is friends with a profile owner."""
    if not getattr(viewer, 'is_authenticated', False) or person is None:
        return False
    if hasattr(person, 'user_id') and hasattr(person, 'follows'):
        target_profile = person
        target_user = getattr(person, 'user', None)
    else:
        target_user = person
        try:
            target_profile = person.profile
        except Exception:
            return False
    if target_user is None:
        return False
    if viewer.pk == target_user.pk:
        return True
    try:
        viewer_profile = viewer.profile
    except Exception:
        return False
    return (
        target_profile.follows.filter(pk=viewer_profile.pk).exists()
        and viewer_profile.follows.filter(pk=target_profile.pk).exists()
    )
