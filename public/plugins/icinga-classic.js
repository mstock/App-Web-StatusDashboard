(function () {
	'use strict';

	angular.module('StatusDashboard').directive('icingaClassic', [
		'statusService',
		function (statusService) {
			var HOST_STATUSES = ['UP', 'DOWN', 'UNREACHABLE'];
			var SERVICE_STATUSES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN', 'DEPENDENT'];
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.getServiceStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						console.log("Old: ", oldValue, "New: ", newValue);

						var hostStats = {};
						var hostStatus = {};
						var serviceStats = {};
						var 	serviceStatus = {};
						HOST_STATUSES.forEach(function (status) {
							hostStats[status] = 0;
							hostStatus[status] = false;
						});
						newValue.hosts.status.host_status.forEach(function (host) {
							hostStats[host.status]++;
							hostStatus[host.status] = true;
						});
						SERVICE_STATUSES.forEach(function (status) {
							serviceStats[status] = 0;
							serviceStatus[status] = false;
						});
						newValue.services.status.service_status.forEach(function (service) {
							serviceStats[service.status]++;
							serviceStatus[service.status] = true;
						});
						scope.hostStats = hostStats;
						scope.hostStatus = hostStatus;
						scope.serviceStats = serviceStats;
						scope.serviceStatus = serviceStatus;
					});
				},
				replace:     false,
				templateUrl: 'templates/icinga-classic.html',
				scope:       {
					statusId: '@statusId'
				}
			}
		}
	]);
}());
