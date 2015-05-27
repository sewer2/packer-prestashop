#!/bin/bash -ex

git clone https://github.com/ClodoCorp/charm-prestashop.git charms/trusty/prestashop
git clone https://github.com/sewer2/packer-nginx-cache-proxy.git charms/trusty/nginx

juju deploy --repository=charms/ local:trusty/prestashop --to 0 || juju deploy --repository=charms/ local:trusty/prestashop --to 0 || exit 1;

juju add-relation mysql prestashop

juju expose prestashop

for s in mysql prestashop; do
    while true; do
        juju status $s/0 --format=json | jq ".services.$s.units" | grep -q '"agent-state": "started"' && break
        echo "waiting 5s"
        sleep 5s
    done
done

sed -i "s/Listen 80/#Listen 80/" /etc/apache2/ports.conf
service apache2 restart

cp /etc/rc.local /etc/rc.local.tmp
echo -e "#!/bin/bash\nwhile true; do if ls /srv/www/htdocs | grep -q admin.; then rm -rf /srv/www/htdocs/install; mv -f /etc/rc.local.tmp /etc/rc.local;  break; fi; sleep 1; done &" > /etc/rc.local

juju deploy --repository=charms/ local:trusty/nginx --to 0 || juju deploy --repository=charms/ local:trusty/nginx-proxy --to 0 || exit 1;

juju add-relation prestashop nginx
juju set nginx cache=true 
juju set nginx default-route="prestashop"

for s in nginx; do
    while true; do
        juju status $s/0 --format=json | jq ".services.$s.units" | grep -q '"agent-state": "started"' && break
        echo "waiting 5s"
        sleep 5s
    done
done


while true; do
    curl -L -s http://127.0.0.1 2>&1 >/dev/null && break
    echo "waiting 5s"
    sleep 5s
done


#fstrim -v /
