# getpasss to hide password in display

from __future__ import annotations

import getpass
from app.database import SessionLocal
from app.models import Admin
from app.services.admin_auth_service import hash_admin_password

#create admin 
def create_admin():

    db = SessionLocal()

    name = input("Admin Name: ")
    email = input("Admin Email: ")
    password = getpass.getpass("Admin Password: ")

    #check deuplicate email
    existing_admin = db.query(Admin).filter(
        Admin.email == email
    ).first()

    if existing_admin:
        print("Admin with this email already exists.")
        db.close()
        return

    #hash admin password
    password_hash = hash_admin_password(password)

    #create admin
    admin = Admin(
        name = name,
        email = email,
        password_hash = password_hash,
        role = "ADMIN",
        is_active = True
    )

    db.add(admin)
    db.commit()
    db.refresh(admin)

    print("Admin created successfully.")
    print(f"Admin ID: {admin.id}")

    db.close()

 #script entry point
if __name__ == "__main__":
    create_admin()