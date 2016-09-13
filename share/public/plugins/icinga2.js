(function () {
	'use strict';

	angular.module('StatusDashboard').directive('icinga2', [
		'statusService',
		function (statusService) {
			var HOST_STATUSES = ['UP', 'DOWN', 'UNREACHABLE'];
			var SERVICE_STATUSES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN'];
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						var hostStats = {};
						var hostStatus = {};
						var serviceStats = {};
						var serviceStatus = {};
						HOST_STATUSES.forEach(function (status) {
							hostStats[status] = 0;
							hostStats[status + '_ACKNOWLEDGED'] = 0;
							hostStatus[status] = false;
						});
						newValue.hosts.forEach(function (host) {
							var hostState = HOST_STATUSES[host.host_state];
							hostStats[hostState]++;
							if (host.host_acknowledged === 1) {
								hostStats[hostState + '_ACKNOWLEDGED']++;
							}
							hostStatus[hostState] = true;
						});
						SERVICE_STATUSES.forEach(function (status) {
							serviceStats[status] = 0;
							serviceStats[status + '_ACKNOWLEDGED'] = 0;
							serviceStatus[status] = false;
						});
						newValue.services.forEach(function (service) {
							var serviceState = SERVICE_STATUSES[service.service_state];
							serviceStats[serviceState]++;
							if (service.service_acknowledged === 1) {
								serviceStats[serviceState + '_ACKNOWLEDGED']++;
							}
							serviceStatus[serviceState] = true;
						});
						scope.hostStats = hostStats;
						scope.hostStatus = hostStatus;
						scope.serviceStats = serviceStats;
						scope.serviceStatus = serviceStatus;
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/icinga.html',
				scope:       {
					statusId:    '@statusId',
					statusTitle: '@statusTitle'
				}
			}
		}
	]);
}());
