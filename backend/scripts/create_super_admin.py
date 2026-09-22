# getpass because We'll ask for the password through the terminal without displaying it
from __future__ import annotations

import getpass

from app.database import SessionLocal
from app.models import Admin
from app.services.admin_auth_service import hash_admin_password

#super admin
def create_super_admin():
    db = SessionLocal()

    name = input("Super Admin name: ")
    email = input("Super Admin email: ")
    password = getpass.getpass("Super Admin password: ")

    existing_admin = db.query(Admin).filter(
        Admin.email == email
    ).first()

    if existing_admin:
        print("Admin with this email already exists.")
        db.close()
        return
    #hash super  admin password 
    password_hash = hash_admin_password(password)

    #create super admin
    admin = Admin(
            name = name,
        email = email,
        password_hash = password_hash,
        role = "SUPER_ADMIN",
        is_active = True
    )

    db.add(admin)
    db.commit()
    db.refresh(admin)

    print("Super Admin created successfully.")
    print(f"Admin ID: {admin.id}")
    db.close()

#script entry point 
if __name__ == "__main__":
    create_super_admin()