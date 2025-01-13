control 'SV-230484' do
  title "RHEL 8 must securely compare internal information system clocks at
least every 24 hours with a server synchronized to an authoritative time
source, such as the United States Naval Observatory (USNO) time servers, or a
time server designated for the appropriate DoD network (NIPRNet/SIPRNet),
and/or the Global Positioning System (GPS)."
  desc 'Inaccurate time stamps make it more difficult to correlate events and
can lead to an inaccurate analysis. Determining the correct time a particular
event occurred on a system is critical when conducting forensic analysis and
investigating system events. Sources outside the configured acceptable
allowance (drift) may be inaccurate.

    Synchronizing internal information system clocks provides uniformity of
time stamps for information systems with multiple system clocks and systems
connected over a network.

    Organizations should consider endpoints that may not have regular access to
the authoritative time server (e.g., mobile, teleworking, and tactical
endpoints).

    If time stamps are not consistently applied and there is no common time
reference, it is difficult to perform forensic analysis.

    Time stamps generated by the operating system include date and time. Time
is commonly expressed in Coordinated Universal Time (UTC), a modern
continuation of Greenwich Mean Time (GMT), or local time with an offset from
UTC.

    RHEL 8 utilizes the "timedatectl" command to view the status of the
"systemd-timesyncd.service". The "timedatectl" status will display the
local time, UTC, and the offset from UTC.

    Note that USNO offers authenticated NTP service to DoD and U.S. Government
agencies operating on the NIPR and SIPR networks. Visit
https://www.usno.navy.mil/USNO/time/ntp/dod-customers for more information.'
  desc 'check', 'Verify RHEL 8 is securely comparing internal information system clocks at
least every 24 hours with an NTP server with the following commands:

    $ sudo grep maxpoll /etc/chrony.conf

    server 0.us.pool.ntp.mil iburst maxpoll 16

    If the "maxpoll" option is set to a number greater than 16 or the line is
commented out, this is a finding.

    Verify the "chrony.conf" file is configured to an authoritative DoD time
source by running the following command:

    $ sudo grep -i server /etc/chrony.conf
    server 0.us.pool.ntp.mil

    If the parameter "server" is not set or is not set to an authoritative
DoD time source, this is a finding.'
  desc 'fix', "Configure the operating system to securely compare internal information
system clocks at least every 24 hours with an NTP server by adding/modifying
the following line in the /etc/chrony.conf file.

    server [ntp.server.name] iburst maxpoll 16"
  impact 0.5
  ref 'DPMS Target Red Hat Enterprise Linux 8'
  tag severity: 'medium'
  tag gtitle: 'SRG-OS-000355-GPOS-00143'
  tag satisfies: ['SRG-OS-000355-GPOS-00143', 'SRG-OS-000356-GPOS-00144', 'SRG-OS-000359-GPOS-00146']
  tag gid: 'V-230484'
  tag rid: 'SV-230484r877038_rule'
  tag stig_id: 'RHEL-08-030740'
  tag fix_id: 'F-33128r568199_fix'
  tag cci: ['CCI-001891']
  tag nist: ['AU-8 (1) (a)']
  tag 'host'

  only_if('This control is Not Applicable to containers', impact: 0.0) {
    !virtualization.system.eql?('docker')
  }

  # Get inputs
  authoritative_timeservers = input('authoritative_timeservers')
  authoritative_timeservers_exact = input('authoritative_timeservers_exact')

  # Get the system server values
  # Converts to array if only one value present
  time_sources = [chrony_conf.server].flatten

  # Get and map maxpoll values to an array
  unless time_sources.nil?
    # Map max poll values only
    max_poll_values = time_sources.map { |val|
      val.match?(/.*maxpoll.*/) ? val.gsub(/.*maxpoll\s+(\d+)(\s+.*|$)/, '\1').to_i : 10
    }

    # Map server values only
    server_values = time_sources.map { |val|
      val.split(' ').first
    }
  end

  # Verify the "chrony.conf" file is configured to a time source by running the following command:
  describe chrony_conf do
    its('server') { should_not be_nil }
  end

  unless time_sources.nil?
    # Verify the chrony.conf file is configured to at least one authoritative DoD time source
    # Check for valid maxpoll value <17
    describe 'chrony.conf' do
      # authoritative_timeservers_exact specifies whether to verify all inputted timeservers or just one
      if authoritative_timeservers_exact
        it 'should include all specified valid timeservers' do
          expect(authoritative_timeservers.all? { |input|
                   server_values.include?(input) && max_poll_values[server_values.index(input)] < 17
                 }).to be true
        end
      else
        it 'should include at least one valid timeserver' do
          expect(authoritative_timeservers.any? { |input|
            server_values.include?(input) && max_poll_values[server_values.index(input)] < 17
          }).to be true
        end
      end
    end
  end
end
