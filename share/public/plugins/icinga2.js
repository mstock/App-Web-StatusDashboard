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
							hostStatus[status] = false;
						});
						newValue.hosts.forEach(function (host) {
							hostStats[HOST_STATUSES[host.host_state]]++;
							hostStatus[HOST_STATUSES[host.host_state]] = true;
						});
						SERVICE_STATUSES.forEach(function (status) {
							serviceStats[status] = 0;
							serviceStatus[status] = false;
						});
						newValue.services.forEach(function (service) {
							serviceStats[SERVICE_STATUSES[service.service_state]]++;
							serviceStatus[SERVICE_STATUSES[service.service_state]] = true;
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
