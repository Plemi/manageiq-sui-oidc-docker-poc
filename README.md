# manageiq-sui-oidc-docker-poc

## ManageIQ Self-Service UI OIDC with Keycloak

This project is a POC (proof of concept) to demonstrate that **external authentication** on **ManageIQ Appliance** can work with **OIDC** ([OpenID Connect](https://en.wikipedia.org/wiki/OpenID_Connect "OpenID Connect")) both:
- on the Appliance’s **Web administrative UI**
- and on the **Self-Service UI** (and partially on the REST API, too)

It relies on an experimental implementation of the *Ivanchuk* version of **ManageIQ**, and more precisely on 2 forked MIQ official components: 
- the [ManagegIQ Api plugin](https://github.com/Plemi/manageiq-ui-service "ManagegIQ Api plugin"), 
- and the [Service UI app](https://github.com/Plemi/manageiq-api "Service UI app").
(See below for details about these forks).

It uses **Keycloak** as an Identity Provider, and **Ansible** (automation tool) to configure Keycloak with a proper *realm* and a *client* for ManageIQ instance (following [MIQ official guidelnes for OIDC](https://www.manageiq.org/docs/reference/latest/auth/openid_connect "MIQ official guidelnes for OIDC")) and also to load some basic user fixtures (a "foo" test user belonging to a group matching MIQ super administrator group) into Keycloak DB, to easier things.

This POC only requires **Docker** on your host machine, in order to run **3 docker containers** (using docker-compose):
- one for a monolithic Manageiq appliance
- one for Postgresql (needed by Keycloak)
- one for the Keycloak server

All the Apache and OIDC configuration (detailed in ManageIQ official documentation) is handled at docker build stages, and through an ansible playbook at run stage, so sandbox tests can be done quickly out of the box without the hassle of configuring things first.

As explained below, the POC uses modified versions of manageiq docker images.


### Requirements

You must have **Docker Engine** and **Docker Compose** installed on your machine.
Just follow these official Docker guidelines, depending on your platform :
- Docker Engine : https://docs.docker.com/install/
- Docker Compose : https://docs.docker.com/compose/install/

Although not a requirement, [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git "Git") is obviously needed to clone this repository (the preferred way to get the source code of this project).


### Installation

1. **Clone (or download) this project**

Open a terminal, and paste the following:
```shell
git clone https://github.com/Plemi/manageiq-sui-oidc-docker-poc.git
```

2. **Add some entries in your /etc/hosts file**

On Mac or Linux platform, simply edit the /etc/hosts file with your preferred editor, for instance vim:
```shell
vim /etc/hosts
```
Add the following lines at the end, then save and quit:
~~~~
127.0.0.1       keycloak
127.0.0.1       server
~~~~

On Windows, follow [theese steps](https://www.howtogeek.com/howto/27350/beginner-geek-how-to-edit-your-hosts-file/ "how to edit hosts file on Windows").

3. **Launch docker-compose stack**

Move to the root of your local copy of the project: 
```shell
cd manageiq-sui-oidc-docker-poc
```
Then just launch docker-compose command:
```shell
docker-compose -f compose.yml up
```
**Notes**: the first time the stack is built, and depending on your internet connection, it can take about 5 or 10 minutes for the whole process to complete (the time to download parent docker images, build new ones, and run the containers), so be patient. For this reason, launching the stack in the background (adding option -d in the docker-compose command) is not advised, at least the first time.

You will know that everything is correctly started when you will be able:
- to **browse ManageIQ admin web view** on your host at this url: https://server/#/ (the first time, the browser will complain about incorrect SSL certificates, it's OK, just go through);
- to **access Keycloak interface** from there: http://localhost:8080.


4. **Configure Keycloak and load fixtures**

Open another terminal window, and launch this docker command:
```shell
docker exec -it manageiq-sui-oidc-docker-poc_keycloak_1 /opt/ansible/load-fixtures.sh
```
Wait for the whole playbook to finish (it takes about 30/40 sec).

5. **Activate OIDC on the MIQ Appliance**

As explained in the [official ManageIQ documention](https://www.manageiq.org/docs/reference/latest/auth/openid_connect#configuring-the-administrative-ui "official ManageIQ documention"), you need to complete the following steps:

From a browser (Chrome, Firefox, etc.), navigate to this url: https://server/#/. 
Login as admin (default admin password is "smartvm"), then in Configure → Configuration → Authentication section:

1. Set mode to *External (httpd)*

2. Check: Provider Type: *Enable OpenID-Connect*.

3. Check: *Enable Single Signon*.

4. Check: *Get User Groups from External Authentication (httpd)*

Click Save and log out from admin web view.


### Usage

#### OIDC on the admin view

To test OIDC external authentication on the admin web view: 
- Just go to the admin home page here: https://server/#/
- Then click on "Log in to corporate system", you'll be redirect to Keycloak realm login page.
- From there, sign in as "foo" user, using "foo" as username, and "bar" as password.
- Validate and you will be redirected to the admin dashboard view, logged in as "foo" super admin user.

Notes : Obviously, authenticating to the admin interface requires to own the proper rights. That's the case for our "foo" user who belongs to the "EvmGroup-super_administrator" group.

#### OIDC on the self service UI

To test OIDC external authentication on the self service UI: 
- Just browse this url: https://server/ui/service/login
- From there, if OIDC has been properly enabled on the appliance, you will see two buttons allowing you to sign in on the admin or the SUI interface.
- Click on the SUI button. And from the Keycloak realm login view, use the same login/pass as for the admin UI (foo/bar).
- You'll be redirected to the Self Service UI, and logged in as "foo" user.

#### Switching between admin / SUI interfaces

When you are logged out, you can use the link present at the top of the Keycloak realm login page if you need to switch between admin and user interfaces.

When you are logged in on the SUI, you can use the shortcut in the top menu to reach the admin view. You'll be connected without having to re-authenticate a second time.

Note that as we use the same keycloak client for both interfaces, once you are connected on one, you can connect on the other without the need to re-authenticate because a valid session already exists on the Keycloak side.

But keep in mind that as the admin interface and the self service interface are two different apps, you'll be connected on each with a different session on the client side, so you need to **log out individually** on each one.

#### Adding new users in Keycloak interface

If you want to create new users (or modify user foo) to test authentication with your own data, you can do the following:
1. Authenticate as admin in the Keycloak web interface (http://localhost:8080/auth/admin/), using admin / Pa55w0rd as credentials (password is set in the compose.yml file).
2. Go to the Users section (http://localhost:8080/auth/admin/master/console/#/realms/manageiq/users) and click the "Add User" button on the right. Fill in the form, validate and don't forget to create credentials once the user is created (from the Credentials tab in the user view).
3. Attach the new user to at least one valid group (a group named exactly as an existing ManageIQ group). Add new group(s) first from the groups section if necessary, then attach user to it(s) from the Groups tab in the user view.
4. Then you can try to authenticate on ManageIQ with your newly created user credentials.

**Notes**: you can also modify manageiq-users.json and manageiq-group.json data fixtures (located in the keycloak/ansible/roles/import-fixtures/files/manageiq-realm-data/ directory) or create your own .json files and use our ansible playbook (or a new one) to load your data from a docker command
(see keycloak/ansible/roles/import-fixtures/tasks/main.yml).

### Based upon forked projects of ManageIQ

This POC uses the following forks of official ManageIQ repositories / components :

- Service UI app : https://github.com/Plemi/manageiq-ui-service (the fork adds support for SSO (SAML, OIDC) user authentication in the Service UI)
- ManagegIQ Api plugin : https://github.com/Plemi/manageiq-api (which is based on this PR https://github.com/ManageIQ/manageiq/pull/14959/files by Abellotti)
- Core ManageIQ app : https://github.com/Plemi/manageiq (which has a modified Gemfile to install the forked API plugin version)
- ManageIQ Pods : https://github.com/Plemi/manageiq-pods (containing modified Dockerfiles pointing to the previous forked projects, in order to build proper docker images)

Please be aware that these forks only work with the *Hammer* and *Ivanchuk* branches of ManageIQ.

To have an overview of the changes made in the MIQ components, you can take a look into this 2 main commits:

https://github.com/Plemi/manageiq-ui-service/commit/249af259fe32bc48a7aefe752536c909cf909280
https://github.com/Plemi/manageiq-api/commit/47af2f6346228b92e71f4ff6e9937f9111643988




